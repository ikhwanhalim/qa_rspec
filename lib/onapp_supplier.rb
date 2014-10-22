require 'yaml'
require 'helpers/onapp_http'

class OnappSupplier
  include OnappHTTP
  attr_accessor :ntz_id, :dsz_id, :hvz_id, :ts_id, :federation_id

  def initialize
    data = YAML::load_file('config/conf.yml')
    @ip = data['supplier']['ip']
    @ts_id = data['supplier']['ts_id']
    auth "#{@ip}/users/sign_in", data['supplier']['user'], data['supplier']['pass']
  end

  def get_resources
    location_groups = get("#{@ip}/settings/location_groups.json")
    ids = location_groups.map {|z| z['location_group']['id']}
    ids.each do |id|
      ntz = get("#{@ip}/settings/location_groups/#{id}/network_groups.json").first
      dsz = get("#{@ip}/settings/location_groups/#{id}/data_store_groups.json").first
      hvz = get("#{@ip}/settings/location_groups/#{id}/hypervisor_groups.json").first
      if ntz && dsz && hvz
        if !ntz["network_group"]["federation_id"] &&
            !hvz["hypervisor_group"]["federation_id"] &&
            !dsz["data_store_group"]["federation_id"]
          @ntz_id = ntz["network_group"]["id"]
          @dsz_id = dsz["data_store_group"]["id"]
          @hvz_id = hvz["hypervisor_group"]["id"]
        end
      end
    end
  end

  def add_to_federation
    get_resources
    data = {"hypervisor_zone" => {'label'=>'federation-autotest',
                                  'data_store_zone_id'=>@dsz_id,
                                  'data_store_zone_label'=> 'federation-autotest',
                                  'network_zone_id'=>@ntz_id,
                                  'network_zone_label'=>'federation-autotest',
                                  'template_group_id'=>@ts_id}}
    unless @hvz_id
      raise 'HypervisorNotFound'
    else
      response = post("#{@ip}/federation/hypervisor_zones/#{@hvz_id}/add.json", data)
      @federation_id = response['hypervisor_zone']['federation_id']
    end
  end

  def remove_from_federation
    post("#{@ip}/federation/hypervisor_zones/#{@hvz_id}/deactivate.json")
    delete("#{@ip}/federation/hypervisor_zones/#{@hvz_id}/remove")
    @federation_id = nil
  end
end