require 'helpers/api_client'
require 'virtual_machine/vm_base'
require 'helpers/waiter'
require 'singleton'

class FederationTrader
  include Singleton, ApiClient, Waiter

  attr_accessor :subscribed_zone, :vm, :template_store

  def initialize
    data = YAML::load_file('config/conf.yml')
    auth url: data['trader']['url'], user: data['trader']['user'], pass: data['trader']['pass']
  end

  def subscribe(federation_id)
    data = {'hypervisor_zone_namer' =>
                {'hypervisor_group_label' => federation_id,
                 'hypervisor_label' => federation_id,
                 'data_store_group_label' => federation_id,
                 'data_store_label' => federation_id,
                 'network_group_label' => federation_id,
                 'network_label' => federation_id,
                 'image_template_group_label' => federation_id
                }
    }
    response = post("/federation/hypervisor_zones/#{federation_id}/subscribe", data)
    return response if @conn.page.code == '422'
    @subscribed_zone = all_subscribed.detect { |z| z.federation_id == federation_id }
    template_store
  end

  def template_store
    get_all('/template_store').detect { |ts| ts.label ==  @subscribed_zone.federation_id}
  end

  def find_template(label)
    get('/templates/all').detect do |t|
      t.image_template.remote_id =~ /#{@subscribed_zone.federation_id}/ &&
      t.image_template.label == label
    end.image_template
  end

  def search(label)
    zones = get("/federation/hypervisor_zones/unsubscribed", data={q: label})
    zones.map! &:hypervisor_zone
  end

  def all_unsubscribed
    zones = get "/federation/hypervisor_zones/unsubscribed"
    zones.map! &:hypervisor_zone
  end

  def zone_appeared?(federation_id)
    wait_until do
      zone = all_unsubscribed.detect { |z| z.federation_id == federation_id }
      zone ? true : false
    end
  end

  def zone_disappeared?(federation_id)
    wait_until do
      zone = all_unsubscribed.detect { |z| z.federation_id == federation_id }
      zone ? false : true
    end
  end

  def all_subscribed
    zones = get "/settings/hypervisor_zones"
    zones.map { |z| z.hypervisor_group if z.hypervisor_group.traded}.compact
  end

  def unsubscribe_all
    errors = ''
    all_subscribed.each do |z|
      response = delete("/federation/hypervisor_zones/#{z.id}/unsubscribe")
      errors << "Zone #{z.id} has not been removed. " if response['errors']
      next
    end
    Log.error(errors) unless errors.empty?
  end

  def get_all(resource)
    get(resource)
  end

  # VM operations
  def create_vm(template_label, federation_id)
    hypervisors = get('/settings/hypervisors').select {|h| h.hypervisor.label == federation_id}
    Log.error('Hypervisor does not have resources') unless hypervisors
    data = Hashie::Mash.new({'hypervisor' => hypervisors.first.hypervisor,
            'template' => find_template(template_label)
    })
    auth_data = Hashie::Mash.new({'url' => @url, 'user' => @user, 'pass' => @pass})
    @vm = VirtualMachine.new(federation: auth_data)
    @vm.create(nil, nil, data)
    if @vm.errors
      Log.warn @vm.errors.to_s
      return @vm.errors
    end
    Log.error("VM has not been built") unless @vm.is_created?
  end

  def find_vm(identifier)
    @subscribed_zone = all_subscribed.first
    auth_data = Hashie::Mash.new({'url' => @url, 'user' => @user, 'pass' => @pass})
    @vm = VirtualMachine.new(federation: auth_data)
    @vm.find_by_id(identifier)
    @vm.info_update
  end

  def vm_hash
    vm.virtual_machine
  end

  #Tokens
  def use_token(sender, token)
    data = {token: {token: token, sender: sender}}
    post("/federation/trader_tokens", data)
  end

  #Announcements
  def find_announcement(market_id)
    wait_until do
      announcement = all_announcements.detect { |a| a.announcement.federation_id == market_id }
      announcement ? announcement : false
    end
  end

  def all_announcements
    get("/federation/hypervisor_zones/#{subscribed_zone.id}/announcements")
  end

  def announcement_removed?(announcement)
    wait_until do
      all_announcements.include?(announcement) ? false : true
    end
  end

  def edit_announcement(id, text)
    data = {announcement: {text: text}}
    put("/federation/hypervisor_zones/#{subscribed_zone.id}/announcements/#{id}", data)
  end
end
