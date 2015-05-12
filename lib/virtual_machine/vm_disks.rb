require 'helpers/transaction'
require 'virtual_machine/vm_operations_waiter'
require 'pry'

module VmDisks
  include Transaction
  include VmOperationsWaiters

  def disk_wait_for_build(type)    
    disk_id = select_id(type:type)          
    wait_for_transaction(disk_id, 'Disk', 'build_disk')       
  end  
  def disk_wait_for_provision(type)
    disk_id = select_id(type:type)          
    wait_for_transaction(disk_id, 'Disk', 'provisioning')        
  end
  def disk_wait_for_format(type)
    disk_id = select_id(type:type)          
    wait_for_transaction(disk_id, 'Disk', 'format_disk')
  end

  # Find disk by VM's identifier or id
  def find_disks
    @disks = get("/virtual_machines/#{@virtual_machine['id']}/disks")
  end

  def find_disk_by_id(id)
    get("/settings/disks/#{id}")['disk']
  end

  def edit_disk(id:nil, type:'primary', action:'set', value:6, expect_code:204, error_message:'')
    id ||= select_id(type:type)
    size = find_disk_by_id(id)['disk_size'].to_i + value.to_i if action == 'incr'
    size = find_disk_by_id(id)['disk_size'].to_i - value.to_i if action == 'decr'
    size = value.to_i if action == 'set'
    result = put("/settings/disks/#{id}", {disk: {disk_size: size}})
    Log.error ("Unexpected responce code. Expected = #{expect_code}, got = #{api_responce_code} \n #{result}") if api_responce_code.to_i != expect_code.to_i
    if expect_code.to_i == 204.to_i
      wait_for_stop
      wait_for_transaction(id, 'Disk', 'resize_disk')
      wait_for_start
      find_disks
      find_disk_by_id(id)
      true
    else
      result['error'].include?(error_message)
    end
  end

  def add_disk(size:1, is_swap:false, expect_code:201, error_message:'')
    ds = select_max_data_store
    data = {
      data_store_id: ds['id'],
      disk_size: size,
      is_swap: is_swap,
      require_format_disk: true,
      add_to_linux_fstab: true,
      file_system: 'ext3',
      min_iops: 100
    }
    result = post("/virtual_machines/#{@virtual_machine['id']}/disks", {disk: data})
    Log.error ("Unexpected responce code. Expected = #{expect_code}, got = #{api_responce_code} \n #{result}") if api_responce_code.to_i != expect_code.to_i
    disk = result['disk']
    wait_for_transaction(disk['id'], 'Disk', 'build_disk')
    find_disks
    disk['id']
  end
  def migrate_disk(id:nil, ds_id:nil, type:'primary', expect_code:201, error_message:'')
    id ||= select_id(type:type)
    ds_id ||= select_max_data_store(exclude:find_disk_by_id(id)['data_store_id'])['id']
    result = post("#{@route}/disks/#{id}/migrate", {disk:{data_store_id: ds_id}})
    Log.error ("Unexpected responce code. Expected = #{expect_code}, got = #{api_responce_code} \n #{result}") if api_responce_code.to_i != expect_code.to_i
    if expect_code.to_i == 201.to_i
      puts @last_transaction_id
      wait_for_transaction(id, 'Disk', 'migrate_disk')
      find_disks
      find_disk_by_id(id)
      true
    else
      result['error'].include?(error_message)
    end
  end

  def destroy_disk(id)
    params = {force: 1, shutdown_type: 'graceful', required_startup: 1}
    delete("/settings/disks/#{id}", params)
    wait_for_transaction(id, 'Disk', 'destroy_disk')
    find_disks
  end
  def check_primary_disk
    id = select_id(type:'primary')
    Log.info("Comparing primary DISK (ID: #{id})")
    to_compare = primary_disk.to_i
    Log.info("On VM: #{to_compare} MB and on CP:#{find_disk_by_id(id)['disk_size'].to_i * 1024} MB")
    Log.error("Primary disk compare error! On VM: #{to_compare} MB and on CP:#{find_disk_by_id(id)['disk_size'].to_i * 1024} MB") if to_compare/(find_disk_by_id(id)['disk_size'].to_i * 1024).to_f < 0.9
    true
  end
  def check_swap_space
    Log.info('Comparing SWAP space')
    to_compare = swap.to_i
    expected_swap = (calculate_swap*1024)
    Log.info("On VM: #{to_compare} MB and on CP:#{expected_swap} MB")
    Log.error("Swap space compare error! On VM: #{to_compare} MB and on CP:#{expected_swap} MB") if to_compare/expected_swap.to_f  < 0.9
    true
  end
  def check_additional_disk(id)
    Log.info('Comparing Additional disk space')
    to_compare = (mounted_disks.select { |d| d[:mount_point] == find_disk_by_id(id)['mount_point']})
    return false if to_compare.first.nil?
    to_compare = to_compare.first[:size].to_i
    Log.info("On VM: #{to_compare} MB and on CP:#{find_disk_by_id(id)['disk_size'].to_i * 1024} MB")
    Log.error("Space compare error! On VM: #{to_compare} MB and on CP:#{find_disk_by_id(id)['disk_size']} MB") if to_compare/(1024*find_disk_by_id(id)['disk_size'].to_i).to_f  < 0.9
    true
  end


  private

  def select_id(type:'primary')
    if type == 'primary'
      disk = (@disks.select { |d| d['disk']['primary'] }).first
    elsif type == 'swap'
      disk = (@disks.select { |d| d['disk']['is_swap'] }).first
    end
    disk['disk']['id']
  end

  def calculate_swap
    ((@disks.select { |d| d['disk']['is_swap'] }).map{|i| i['disk']['disk_size']}).sum
  end

  def select_max_data_store(exclude:nil)
    hv_id = @virtual_machine['hypervisor_id']
    hv_ds_joins = get("/settings/hypervisors/#{hv_id}/data_store_joins")
    hvz_id = get("/settings/hypervisors/#{hv_id}")['hypervisor']['hypervisor_group_id']
    hvz_ds_joins = get("/settings/hypervisor_zones/#{hvz_id}/data_store_joins")
    ds_joins = hv_ds_joins + hvz_ds_joins
    data_stores = ds_joins.map do |join|
      id = join['data_store_join']['data_store_id']
      get("/settings/data_stores/#{id}")['data_store']
    end
    data_stores.reject! {|ds| ds['id'] == exclude} if exclude
    data_store = data_stores.max_by {|ds| ds['data_store_size'].to_i - ds['usage'].to_i}
    free_space = data_store['data_store_size'].to_i - data_store['usage'].to_i
    Log.error("No space left on datastore (#{free_space}GB)") if free_space <= 5
    data_store
  end
end