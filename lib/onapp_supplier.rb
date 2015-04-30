require 'yaml'
require 'helpers/onapp_http'
require 'helpers/template_manager'
require 'helpers/hypervisor'
require 'virtual_machine/vm_base'

class OnappSupplier
  include OnappHTTP
  include TemplateManager
  include Hypervisor
  attr_accessor :published_zone, :vm, :resources

  def initialize
    data = YAML::load_file('config/conf.yml')
    url = data['supplier']['url']
    user = data['supplier']['user']
    pass = data['supplier']['pass']
    auth url: url, user: user, pass: pass
  end

  def get_publishing_resources
    hv_zones = get("/settings/hypervisor_zones").select {|z| z["hypervisor_group"]["location_group_id"]}
    hv_zones.each do |hv_zone|
      id = hv_zone["hypervisor_group"]["id"]
      hv = for_vm_creation(ENV['VIRT_TYPE'], id)
      if hv
        nt_joins = get("/settings/hypervisor_zones/#{id}/network_joins")
        nt_joins += get("/settings/hypervisors/#{hv['id']}/network_joins")
        ds_joins = get("/settings/hypervisor_zones/#{id}/data_store_joins")
        ds_joins += get("/settings/hypervisors/#{hv['id']}/data_store_joins")
        nt = get("/settings/networks/#{nt_joins.first['network_join']['network_id']}")['network']
        nt_zone = get("/settings/network_zones/#{nt['network_group_id']}")['network_group'] || Log.error("Network not attached")
        ds = get("/settings/data_stores/#{ds_joins.first['data_store_join']['data_store_id']}")['data_store']
        ds_zone = get("/settings/data_store_zones/#{ds['data_store_group_id']}")['data_store_group'] || Log.error("Data store not attached")
        location_id = hv_zone["hypervisor_group"]["location_group_id"]
        Log.error("Data store group not in location group") if ds_zone['location_group_id'] != location_id
        Log.error("Network group not in location group") if nt_zone['location_group_id'] != location_id
        return {'hypervisor_group' => hv_zone["hypervisor_group"], 'data_store_group' => ds_zone,  'network_group' => nt_zone}
      end
    end
    Log.error "HypervisorGroupNotFound"
  end

  def add_to_federation(private: 0, label: nil)
    get_template(ENV['TEMPLATE_MANAGER_ID'])
    @resources ||= get_publishing_resources
    @data_store_group = @resources['data_store_group']
    @network_group = @resources['network_group']
    @hvz_id = @resources['hypervisor_group']['id']
    stamp = 'federation-autotest' + DateTime.now.strftime('-%d-%m-%y(%H:%M:%S)')
    data = { 'hypervisor_zone' => {'label' => label || stamp,
                               'private' => private,
                               'data_store_zone_id' => @data_store_group['id'],
                               'network_zone_id' => @network_group['id'],
                               'template_group_id' => @template_store['id']}}
    response = post("/federation/hypervisor_zones/#{@hvz_id}/add", data)
    Log.error(response.values.join("\n")) if response['errors'].any?
    @published_zone = get("/settings/hypervisor_zones/#{@hvz_id}").values.first
  end

  def disable_zone(id=@published_zone['id'])
    @published_zone = post("/federation/hypervisor_zones/#{id}/deactivate").values.first
  end

  def enable_zone(id=@published_zone['id'])
    @published_zone = post("/federation/hypervisor_zones/#{id}/activate").values.first
  end

  def remove_from_federation(id=@published_zone['id'])
    delete("/federation/hypervisor_zones/#{id}/remove")
    @published_zone = nil if all_federated.empty?
  end

  def all_federated
    zones = get "/settings/hypervisor_zones"
    zones.map! { |z| z["hypervisor_group"] }
    zones.delete_if { |z| z['federation_id'] == nil }
  end

  def remove_all_from_federation
    all_federated.each do |z|
      disable_zone(z['id'])
      remove_from_federation(z['id'])
    end
  end

  def hypervisors_detach(id=@published_zone['id'])
    @hypervisors_ids = get("/settings/hypervisor_zones/#{id}/hypervisors").map do |hv|
      hv['hypervisor']['id']
    end
    post("/settings/hypervisor_zones/#{id}/hypervisors/detach_range", {ids: @hypervisors_ids})
  end

  def hypervisors_attach(id=@published_zone['id'])
    post("/settings/hypervisor_zones/#{id}/hypervisors/attach_range", {ids: @hypervisors_ids})
  end

  def data_stores_detach
    id = @data_store_group['id']
    @data_stores_ids = get("/settings/data_store_zones/#{id}/data_stores").map do |ds|
      ds['data_store']['id']
    end
    post("/settings/data_store_zones/#{id}/data_stores/detach_range", {ids: @data_stores_ids})
  end

  def data_stores_attach
    id = @data_store_group['id']
    post("/settings/data_store_zones/#{id}/data_stores/attach_range", {ids: @data_stores_ids})
  end

  # VM operations
  def find_vm(label)
    auth_data = {'url' => @url, 'user' => @user, 'pass' => @pass}
    @vm = VirtualMachine.new(federation: auth_data)
    @vm.find_by_label(label)
    @vm.info_update
  end

  #Tokens
  def generate_token(receiver)
    data = {token: {receiver: receiver}}
    post("/federation/hypervisor_zones/#{@hvz_id}/supplier_tokens", data)
  end

  def get_token(receiver)
    10.times do
      token = get("/federation/hypervisor_zones/#{@hvz_id}/supplier_tokens").select do |t|
        t['token']['receiver'] == receiver
      end.first
      return token if token
      sleep 1
    end
    Log.error('Token not found')
  end
end
