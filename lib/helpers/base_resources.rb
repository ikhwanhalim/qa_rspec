require 'yaml'
require_relative 'onapp_http'

module BaseResources
  def get_dsz_id(hvz_id)
    dsz_id = nil
    ds_joins = get("/settings/hypervisor_zones/#{hvz_id}/data_store_joins")
    if !ds_joins.any?
      hv_id = get("/settings/hypervisor_zones/#{hvz_id}/hypervisors").first['hypervisor']['id']
      ds_joins = get("/settings/hypervisors/#{hv_id}/data_store_joins")
    end
    ds_id = ds_joins.first['data_store_join']['data_store_id']
    ds = get("/settings/data_stores/#{ds_id}")
    dsz_id = ds['data_store']['data_store_group_id']

    return dsz_id
  end

  def get_net_zone_id(hvz_id)
    net_zone_id = nil
    network_joins = get("/settings/hypervisor_zones/#{hvz_id}/network_joins")
    network_id = network_joins.first['network_join']['network_id']
    network = get("/settings/networks/#{network_id}")
    net_zone_id = network['network']['network_group_id']
    return net_zone_id
  end
end

