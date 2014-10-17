require 'json'
require 'yaml'
require 'mechanize'

class OnappSuppier
  attr_accessor :conn, :ntz_id, :dsz_id, :hvz_id, :ts_id, :federation_id

  def initialize
    data = YAML::load(open(File.expand_path(File.dirname(__FILE__) + '/../config/market.yml')))
    @conn = Mechanize.new
    @ip = data['supplier']['ip']
    @ts_id = data['supplier']['ts_id']
    @conn.add_auth "#{@ip}/users/sign_in",
                   data['supplier']['login'],
                   data['supplier']['pass']
  end

  def get(url)
    JSON.parse @conn.get(url).body
  end

  def post(url, data="")
    curl = @conn.post(url, data.to_json, {'Content-Type' => 'application/json'})
    JSON.parse(curl.body)
  end

  def delete(url)
    @conn.delete(url)
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
  end
end