require 'yaml'
require 'helpers/onapp_http'
require 'json'
require 'onapp_billing'

class OnappBaseResource
  include OnappHTTP
  attr_accessor :br_id, :data

  def initialize
    config = YAML::load_file('./config/conf.yml')
    @url = config['url']
    @user = config['user']
    @pass = config['pass']
    auth("#{@url}/users/sign_in", @user, @pass)
    @zones_data = {
        :backup => {
            :url => 'settings/backup_server_zones.json',
            :tag => "backup_server_group"
        },
        :store => {
            :url => 'settings/data_store_zones.json',
            :tag => 'data_store_group'
        },
        :edge => {
            :url => 'edge_groups.json',
            :tag => 'edge_group'
        },
        :hypervisor => {
            :url => 'settings/hypervisor_zones.json',
            :tag => 'hypervisor_group'
        },
        :network => {
            :url => 'settings/network_zones.json',
            :tag => 'network_group'
        },
        :recipe => {
            :url => 'recipe_groups.json',
            :tag => ''
        },
        :template => {
            :url => 'template_store.json',
            :tag => ''
        }
    }

  end

  def create_base_resource(bp_id, data)
    params = {}
    params[:base_resource] = data
    response = post("#{@url}/billing_plans/#{bp_id}/base_resources.json", params)

    if response.has_key?('base_resource')
      @br_id = response['base_resource']['id']
      @data = response['base_resource']
    else
      @data = response['errors']
    end
  end

  def edit_base_resource(bp_id, br_id, data)
    params = {}
    params[:base_resource] = data
    response = put("#{@url}/billing_plans/#{bp_id}/base_resources/#{br_id}.json", params)
    if !response.nil? and response.has_key?('errors')
      @data = response['errors']
    end
  end

  def get_base_resource(bp_id, br_id)
    response = get("#{@url}/billing_plans/#{bp_id}/base_resources/#{br_id}.json")
    if response.has_key?('base_resource')
      @data = response['base_resource']
    else
      @data = response['errors']
    end
  end

  def delete_base_resource(bp_id, br_id, data = '')
    response = delete("#{@url}/billing_plans/#{bp_id}/base_resources/#{br_id}.json", data)
    puts response
    if response.is_a?(Hash) and response.has_key?('errors')
      @data = response['errors']
    end
  end

  def get_zone_id(type=nil)
    response = get("#{@url}/#{@zones_data[type][:url]}")
    if @zones_data[type][:tag] == ''
      id = response.first['id']
    else
      id = response.first[@zones_data[type][:tag]]['id']
    end
    return id
  end

  # Return ids for HVZ, DSZ, NTZ (for bp before VS creation)
  def hdn_zones_ids(virtualization=[])
    hvz_id = get_hvz_id(virtualization)
    dsz_id = get_dsz_id(hvz_id)
    netz_id = get_net_zone_id(hvz_id)
    return {:hvz_id => hvz_id,
            :dsz_id => dsz_id,
            :netz_id => netz_id
    }
  end

  # For min IOPS base resources
  def dsz_zone_id_by_type(type=nil)
    dsz = nil
    data_stores = get("#{@url}/settings/data_stores.json")
    data_stores.each do |data_store|
      if data_store['data_store']['data_store_type'] == type
        dsz = data_store['data_store']['data_store_group_id']
        break
      end
    end
    return dsz
  end
  
  protected
  def get_hvz_id(virtualization)
    hvs = get("#{@url}/settings/hypervisors.json")
    hvs_collector = []
    hvz_id = nil
    hvs.each do |hv|
      if hv['hypervisor']['server_type'] == 'virtual' and
          hv['hypervisor']['hypervisor_type'].in?(virtualization) and
          hv['hypervisor']['enabled'] == true and
          hv['hypervisor']['online'] == true
        hvs_collector.append([hv['hypervisor']['free_memory'], hv['hypervisor']['hypervisor_group_id']],)
      end
    end
    if !hvs_collector.empty?
      hvz_id = hvs_collector.sort.last.last
    end
    return hvz_id
  end

  def get_dsz_id(hvz_id)
    dsz_id = nil
    ds_joins = get("#{@url}/settings/hypervisor_zones/#{hvz_id}/data_store_joins.json")
    ds_id = ds_joins.first['data_store_join']['data_store_id']
    ds = get("#{@url}/settings/data_stores/#{ds_id}.json")
    dsz_id = ds['data_store']['data_store_group_id']
    return dsz_id
  end

  def get_net_zone_id(hvz_id)
    net_zone_id = nil
    network_joins = get("#{@url}/settings/hypervisor_zones/#{hvz_id}/network_joins.json")
    network_id = network_joins.first['network_join']['network_id']
    network = get("#{@url}/settings/networks/#{network_id}.json")
    net_zone_id = network['network']['network_group_id']
    return net_zone_id
  end
end
