require 'yaml'
require 'helpers/onapp_http'
require 'virtual_machine/vm_base'
require 'virtual_machine/vm_operations_waiter'

class OnappTrader
  include OnappHTTP
  include VmOperationsWaiters

  attr_accessor :subscribed_zone, :vm, :template_store

  def initialize
    data = YAML::load_file('config/conf.yml')
    url = data['trader']['url']
    user = data['trader']['user']
    pass = data['trader']['pass']
    auth url: url, user: user, pass: pass
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
    @subscribed_zone = all_subscribed.detect { |z| z['federation_id'] == federation_id }
    template_store
  end

  def template_store
    get_all('/template_store').detect { |ts| ts['label'] ==  @subscribed_zone['federation_id']}
  end

  def find_template(label)
    template = get('/templates/all').detect do |t|
      t['image_template']['remote_id'] =~ /#{@subscribed_zone['federation_id']}/ &&
      t['image_template']['label'] == label
    end
    template['image_template']
  end

  def search(label)
    zones = get("/federation/hypervisor_zones/unsubscribed", data={q: label})
    zones.map! { |z| z["hypervisor_zone"]}
  end

  def all_unsubscribed
    zones = get "/federation/hypervisor_zones/unsubscribed"
    zones.map! { |z| z["hypervisor_zone"]}
  end

  def all_subscribed
    zones = get "/settings/hypervisor_zones"
    zones.map! { |z| z["hypervisor_group"]}
    zones.select! { |z| z['traded'] == true }
  end

  def unsubscribe_all
    errors = ''
    all_subscribed.each do |z|
      response = delete("/federation/hypervisor_zones/#{z['id']}/unsubscribe")
      errors << "Zone #{z['id']} has not been removed. " if response['errors']
      next
    end
    Log.error(errors) unless errors.empty?
  end

  def get_all(resource)
    get(resource)
  end

  def wait_for_publishing(federation_id)
    10.times do
      zones = get("/federation/hypervisor_zones/unsubscribed")
      zones.each do |hvz|
        return hvz if hvz['hypervisor_zone']['federation_id'] == federation_id
      end
      sleep 1
    end
    Log.error("Zone has not been published")
  end

  # VM operations
  def create_vm(template_label, federation_id)
    hypervisors = get('/settings/hypervisors').select {|h| h['hypervisor']['label'] == federation_id}
    Log.error('Hypervisor does not have resources') unless hypervisors
    data = {'hypervisor' => hypervisors.first['hypervisor'],
            'template' => find_template(template_label)
    }
    auth_data = {'url' => @url, 'user' => @user, 'pass' => @pass}
    @vm = VirtualMachine.new(federation: auth_data)
    @vm.create(nil, nil, data)
    if @vm.errors
      Log.warn @vm.errors.to_s
      return @vm.errors.to_s
    end
    Log.error("VM has not been built") unless @vm.is_created?
  end

  def find_vm(identifier)
    @subscribed_zone = all_subscribed.first
    auth_data = {'url' => @url, 'user' => @user, 'pass' => @pass}
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
    10.times do
      all_announcements.each do |a|
        return a if a['announcement']['federation_id'] == market_id
      end
      sleep 1
    end
    Log.error('Announcement was not created on the market')
  end

  def all_announcements
    get("/federation/hypervisor_zones/#{subscribed_zone['id']}/announcements")
  end

  def announcement_removed?(announcement)
    10.times do
      return true unless all_announcements.include?(announcement)
      sleep 1
    end
    Log.error('Announcement was not removed on the market')
  end

  def edit_announcement(id, text)
    data = {announcement: {text: text}}
    put("/federation/hypervisor_zones/#{subscribed_zone['id']}/announcements/#{id}", data)
  end

  #IP addresses
end