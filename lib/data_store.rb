class DataStore
  attr_reader :interface, :id, :label,:identifier, :data_store_size, :data_store_group_id, :enabled, :data_store_type,
              :data_store_size, :usage

  def initialize(disk)
    @disk = disk
    @interface = disk.interface
    @virtual_machine = interface.virtual_machine
  end

  def find(id)
    response = interface.get("/settings/data_stores/#{id}")
    info_update(response)
  end

  def assigned_data_stores_to_hv
    data_stores_ids=Array.new
    ds_joins=interface.get("/settings/hypervisors/#{@virtual_machine.hypervisor_id}/data_store_joins")
    Log.warn(ds_joins)
    ds_joins.each do |join|
      data_stores_ids << join["data_store_join"]["data_store_id"]
    end
    data_stores_ids
  end

  def assigned_data_stores_to_hv_group
    data_stores_ids=Array.new
    ds_joins=interface.get("/settings/hypervisor_zones/#{@virtual_machine.hypervisor_group_id}/data_store_joins")
    ds_joins.each do |join|
      data_stores_ids << join["data_store_join"]["data_store_id"]
    end
    data_stores_ids
  end

  def select_available_data_store_for_migration
    ds_ids = assigned_data_stores_to_hv + assigned_data_stores_to_hv_group
    interface.get('/settings/data_stores').map(&:data_store).each do |ds|
      if ds.id !=@disk.data_store_id && ds.enabled && ds_ids.include?(ds.id) && ds.label !~ /fake/i &&
      (ds.data_store_size - ds.usage) > 0
        info_update(ds)
        Log.info("Data store with id #{ds.id} has been selected for migration")
        return self
      end
    end
    return false
  end

  def info_update(info)
    info.each { |k,v| instance_variable_set("@#{k}", v) }
  end
end