require 'yaml'
require 'helpers/onapp_http'
require 'helpers/template_manager'

class OnappSupplier
  include OnappHTTP
  include TemplateManager
  attr_accessor :published_zone

  def initialize
    data = YAML::load_file('config/conf.yml')
    data['supplier'].each do |k, v|
      instance_variable_set("@#{k}",v)
      eigenclass = class<<self; self; end
      eigenclass.class_eval do
        attr_accessor k
      end
    end
    auth "#{@url}/users/sign_in", @user, @pass
  end

  def not_federated_resources
    location_groups = get("#{@url}/settings/location_groups.json")
    ids = location_groups.map {|z| z['location_group']['id']}
    ids.each do |id|
      ntz = get("#{@url}/settings/location_groups/#{id}/network_groups.json").first["network_group"] rescue next
      dsz = get("#{@url}/settings/location_groups/#{id}/data_store_groups.json").first["data_store_group"] rescue next
      hvz = get("#{@url}/settings/location_groups/#{id}/hypervisor_groups.json").first["hypervisor_group"] rescue next
      if !ntz["federation_id"] && !hvz["federation_id"] && !dsz["federation_id"]
        return {'hypervisor_group' => hvz, 'data_store_group' => dsz,  'network_group' => ntz}
      else
        raise 'HypervisorNotFound'
      end
    end
  end

  def add_to_federation
    get_template(@template_file_name)
    res = not_federated_resources
    stamp = 'federation-autotest' + DateTime.now.strftime('-%d-%m-%y(%H:%M:%S)')
    data = { 'hypervisor_zone' => {'label' => stamp,
                               'data_store_zone_id' => res['data_store_group']['id'],
                               'data_store_zone_label' => stamp,
                               'network_zone_id' => res['network_group']['id'],
                               'network_zone_label' => stamp,
                               'template_group_id' => @template_store['id']}}
    response = post("#{@url}/federation/hypervisor_zones/#{res['hypervisor_group']['id']}/add.json", data)
    raise response.values.join("\n") if response.has_key? 'errors'
    @published_zone = get("#{@url}/settings/hypervisor_zones/#{res['hypervisor_group']['id']}.json").values.first
  end

  def disable_zone(id=@published_zone['id'])
    @published_zone = post("#{@url}/federation/hypervisor_zones/#{id}/deactivate.json").values.first
  end

  def enable_zone(id=@published_zone['id'])
    @published_zone = post("#{@url}/federation/hypervisor_zones/#{id}/activate.json").values.first
  end

  def remove_from_federation(id=@published_zone['id'])
    delete("#{@url}/federation/hypervisor_zones/#{id}/remove.json")
    @published_zone = nil
  end

  def all_federated
    zones = get "#{@url}/settings/hypervisor_zones.json"
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
