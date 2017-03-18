class DataStore
  attr_reader :interface, :id, :label,:identifier, :data_store_size, :data_store_group_id, :enabled, :data_store_type,
              :data_store_size, :usage, :io_limits

  def initialize(disk)
    @disk = disk
    @interface = disk.interface
    find(@disk.data_store_id)
  end

  def find(id)
    response = interface.get("/settings/data_stores/#{id}")
    info_update(response)
  end

  def select_available_data_store_for_migration
    interface.get("/settings/data_store_zones/#{data_store_group_id}/data_stores").map(&:data_store).each do |ds|
      if ds.id !=@disk.data_store_id && ds.enabled && ds.label !~ /fake/i &&
      (ds.data_store_size - ds.usage) >= @disk.disk_size  && data_store_type == 'lvm'
        info_update(ds)
        Log.info("Data store with id #{ds.id} has been selected for migration")
        return self
      end
    end
    return false
  end

  def info_update(info)
    data_store =  info['data_store'] ? info['data_store'] : info
    data_store.each { |k,v| instance_variable_set("@#{k}", v) }
  end
end