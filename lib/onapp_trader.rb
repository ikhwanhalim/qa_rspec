require 'yaml'
require 'helpers/onapp_http'
require 'virtual_machine/vm_base'

class OnappTrader
  include OnappHTTP
  attr_accessor :subscribed_zone, :vm

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
                 'image_template_group_label' => federation_id,
                }
    }
    response = post("/federation/hypervisor_zones/#{federation_id}/subscribe", data)
    return response if response
    @subscribed_zone = all_subscribed.select {|z| z['federation_id'] == federation_id}.first
  end

  def all_unsubscribed
    zones = get "/federation/hypervisor_zones/unsubscribed"
    zones.map! { |z| z["hypervisor_zone"]}
  end

  def all_subscribed
    zones = get "/settings/hypervisor_zones"
    zones.map! { |z| z["hypervisor_group"]}
    zones.delete_if { |z| z['federation_id'] == nil }
  end

  def unsubscribe_all
    all_subscribed.each do |z|
      delete("/federation/hypervisor_zones/#{z['id']}/unsubscribe")
    end
  end

  def get_all(resource)
    get(resource)
  end

  def wait_for_publishing(federation_id)
    zones = []
    10.times do
      return zones if zones.any?
      zones = get("/federation/hypervisor_zones/unsubscribed")
      zones.select!{|hvz| hvz['hypervisor_zone']['federation_id'] == federation_id}
      sleep 1
    end
    Log.error("Zone has not been published")
  end

  # VM operations
  def create_vm(template_label, federation_id)
    hypervisors = get('/settings/hypervisors').select {|h| h['hypervisor']['label'] == federation_id}
    templates = get('/templates/all').select do |t|
      t['image_template']['remote_id'] &&
          t['image_template']['remote_id'].include?(federation_id) &&
          t['image_template']['label'] == template_label
    end
    Log.error('Hypervisor does not have resources') unless hypervisors
    data = {'hypervisor' => hypervisors.first['hypervisor'], 'template' => templates.first['image_template']}
    auth_data = {'url' => @url, 'user' => @user, 'pass' => @pass}
    @vm = VirtualMachine.new(federation: auth_data)
    @vm.create(nil, nil, data)
    errors = @vm.virtual_machine['errors']
    return errors.to_s if errors
    Log.error("VM has not been built") unless @vm.is_created?
  end

  #Tokens
  def use_token(sender, token)
    data = {token: {token: token, sender: sender}}
    post("/federation/trader_tokens", data)
  end
end