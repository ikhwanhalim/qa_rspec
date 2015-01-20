require 'yaml'
require 'helpers/onapp_http'
require 'helpers/template_manager'
require 'helpers/hypervisor'

class OnappSupplier
  include OnappHTTP
  include TemplateManager
  include Hypervisor
  attr_accessor :published_zone

  def initialize
    data = YAML::load_file('config/conf.yml')
    url = data['supplier']['url']
    user = data['supplier']['user']
    pass = data['supplier']['pass']
    auth url: url, user: user, pass: pass
  end

  def not_federated_resources
    raise 'Virtualization type is empty' unless ENV['VIRT_TYPE']
    location_groups = get("/settings/location_groups")
    ids = location_groups.map {|z| z['location_group']['id']}
    ids.each do |id|
      ntz = get("/settings/location_groups/#{id}/network_groups").first["network_group"] rescue next
      dsz = get("/settings/location_groups/#{id}/data_store_groups").first["data_store_group"] rescue next
      hvz = get("/settings/location_groups/#{id}/hypervisor_groups").first["hypervisor_group"] rescue next
      if !ntz["federation_id"] && !hvz["federation_id"] && !dsz["federation_id"] && for_vm_creation(ENV['VIRT_TYPE'], hvz['id'])
        return {'hypervisor_group' => hvz, 'data_store_group' => dsz,  'network_group' => ntz}
      else
        raise 'HypervisorNotFound'
      end
    end
  end

  def add_to_federation
    raise 'Template manager_id is empty' unless ENV['TEMPLATE_MANAGER_ID']
    get_template(ENV['TEMPLATE_MANAGER_ID'])
    res = not_federated_resources
    hvz_id = res['hypervisor_group']['id']
    stamp = 'federation-autotest' + DateTime.now.strftime('-%d-%m-%y(%H:%M:%S)')
    data = { 'hypervisor_zone' => {'label' => stamp,
                               'data_store_zone_id' => res['data_store_group']['id'],
                               'data_store_zone_label' => stamp,
                               'network_zone_id' => res['network_group']['id'],
                               'network_zone_label' => stamp,
                               'template_group_id' => @template_store['id']}}
    response = post("/federation/hypervisor_zones/#{hvz_id}/add", data)
    raise response.values.join("\n") if response.has_key? 'errors'
    @published_zone = get("/settings/hypervisor_zones/#{hvz_id}").values.first
  end

  def disable_zone(id=@published_zone['id'])
    @published_zone = post("/federation/hypervisor_zones/#{id}/deactivate").values.first
  end

  def enable_zone(id=@published_zone['id'])
    @published_zone = post("/federation/hypervisor_zones/#{id}/activate").values.first
  end

  def remove_from_federation(id=@published_zone['id'])
    result = delete("/federation/hypervisor_zones/#{id}/remove")
    if result['errors']
      result
    else
      @published_zone = nil
    end
  end

  def all_federated
    zones = get "/settings/hypervisor_zones"
    zones.map! { |z| z["hypervisor_group"]}
    zones.delete_if { |z| z['federation_id'] == nil }
  end

  def remove_all_from_federation
    all_federated.each do |z|
      disable_zone(z['id'])
      remove_from_federation(z['id'])
    end
  end
end
