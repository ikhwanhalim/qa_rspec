require 'helpers/transaction'
require 'virtual_machine/vm_operations_waiter'

module VmDisks
  include Transaction
  include VmOperationsWaiters

  def disk_wait_for_build(type)    
    disk_id = select_id(type)          
    wait_for_transaction(disk_id, 'Disk', 'build_disk')       
  end  
  def disk_wait_for_provision(type)
    disk_id = select_id(type)          
    wait_for_transaction(disk_id, 'Disk', 'provisioning')        
  end
  def disk_wait_for_format(type)
    disk_id = select_id(type)          
    wait_for_transaction(disk_id, 'Disk', 'format_disk')
  end

  # Find disk by VM's identifier or id
  def find_disks
    @disks = get("/virtual_machines/#{@virtual_machine['id']}/disks")
  end

  def find_disk_by_id(id)
    get("/settings/disks/#{id}")['disk']
  end

  def edit_disk(id:nil, type:'primary', size:6)
    id ||= select_id(type)
    put("/settings/disks/#{id}", {disk: {disk_size: size}})
    wait_for_stop
    wait_for_transaction(id, 'Disk', 'resize_disk')
    wait_for_start
    find_disks
    find_disk_by_id(id)
  end

  def add_disk(label:'AutoTest', size:1, is_swap:false)
    ds = select_max_data_store
    data = {
      label: label,
      data_store_id: ds['id'],
      disk_size: size,
      is_swap: is_swap,
      require_format_disk: true,
      add_to_linux_fstab: true,
      file_system: 'ext3',
      mount_point: '/mnt/' + label,
      min_iops: 100
    }
    disk = post("/virtual_machines/#{@virtual_machine['id']}/disks", {disk: data})['disk']
    wait_for_transaction(disk['id'], 'Disk', 'build_disk')
    find_disks
    disk
  end

  def destroy_disk(id)
    params = {force: 1, shutdown_type: 'graceful', required_startup: 1}
    delete("/settings/disks/#{id}", params)
    wait_for_transaction(id, 'Disk', 'destroy_disk')
    find_disks
  end

  private

  def select_id(type)
    if type == 'primary'
      disk = (@disks.select { |d| d['disk']['primary'] }).first
    elsif type == 'swap'
      disk = (@disks.select { |d| d['disk']['is_swap'] }).first
    end
    disk['disk']['id']
  end

  def select_max_data_store
    hv_id = @virtual_machine['hypervisor_id']
    hv_ds_joins = get("/settings/hypervisors/#{hv_id}/data_store_joins")
    hvz_id = get("/settings/hypervisors/#{hv_id}")['hypervisor']['hypervisor_group_id']
    hvz_ds_joins = get("/settings/hypervisor_zones/#{hvz_id}/data_store_joins")
    ds_joins = hv_ds_joins + hvz_ds_joins
    data_stores = ds_joins.map do |join|
      id = join['data_store_join']['data_store_id']
      get("/settings/data_stores/#{id}")['data_store']
    end
    data_store = data_stores.max_by {|ds| ds['data_store_size'].to_i - ds['usage'].to_i}
    free_space = data_store['data_store_size'].to_i - data_store['usage'].to_i
    Log.error("No space left on datastore (#{free_space}GB)") if free_space <= 5
    data_store
  end
end