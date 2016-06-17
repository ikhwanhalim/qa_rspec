class Disk
  include DiskOperationsWaiters, Waiter
  attr_reader :interface, :route, :add_to_freebsd_fstab, :add_to_linux_fstab,:built,:burst_bw,:burst_iops,:created_at,:data_store_id,
              :disk_size,:disk_vm_number,:file_system,:id,:identifier, :iqn,:is_swap, :label,:locked,:max_bw,
              :max_iops, :min_iops, :mount_point, :primary, :updated_at,:virtual_machine_id, :volume_id,:has_autobackups

  def initialize(virtual_machine)
    @virtual_machine = virtual_machine
    @interface = virtual_machine.interface
    @vm_route = virtual_machine.route
    @acceptable_physycal_error_ratio=0.05
  end

  def disks_route
    "#{@vm_route}/disks"
  end

  def data_store_identifier
    interface.get("/settings/data_stores/#{data_store_id}").data_store.identifier
  end

  #probably it make sense to move this method to another place? to hv class
  def assigned_data_stores_to_hv
    data_stores_ids=Array.new
    ds_joins=interface.get("/settings/hypervisors/#{@virtual_machine.hypervisor_id}/data_store_joins")
    Log.warn(ds_joins)
    ds_joins.each do |join|
      data_stores_ids << join["data_store_join"]["data_store_id"]
    end
    data_stores_ids
  end

  ##probably it make sense to move this method to another place? to hvz class?
  def assigned_data_store_to_hv_group
    data_stores_ids=Array.new
    ds_joins=interface.get("/settings/hypervisor_zones/#{@virtual_machine.hypervisor_group_id}/data_store_joins")
    ds_joins.each do |join|
      data_stores_ids << join["data_store_join"]["data_store_id"]
    end
    data_stores_ids
  end

  def available_data_store_for_migration
    (assigned_data_stores_to_hv + assigned_data_store_to_hv_group).uniq.detect { |id| id != data_store_id }
  end

  def migrate(ds_id = available_data_store_for_migration)
    interface.post("#{@route}/migrate",  {disk: {data_store_id: ds_id}})
    return if interface.conn.page.code != '201'
    wait_for_disk_migrate
    info_update(data_store_id: ds_id)
  end

  def info_update(info=false)
    info ||= interface.get(@route).disk
    info.each { |k,v| instance_variable_set("@#{k}", v) }
    @route = "#{disks_route}/#{id}"
    self
  end

  def create(**params)
    data = interface.post(disks_route, {disk: build_params.merge(params)})
    return if interface.conn.page.code != '201'
    info_update(data.disk)
  end

  def edit(**params)
    params[:label] ||= label
    interface.put(@route, {disk: params})
    return if interface.conn.page.code != '204'
    if params[:disk_size] && params[:disk_size] != disk_size
      wait_for_resize
    elsif params[:mount_point]
      wait_for_update_fstab
    end
    info_update(params)
  end

  def remove(**params)
    data = {force: 1, shutdown_type: 'graceful', required_startup: 1}
    interface.delete(@route, data.merge(params))
    return if interface.conn.page.code != '204'
    wait_for_destroy
  end

  #TODO refactoring
  def detach
    #Detach should supported as default action
    interface.delete(@route)
    return if interface.conn.page.code != '204'
    wait_for_detach
  end

  def build_params
    {
      label: "Disk-#{SecureRandom.hex(4)}",
      disk_size: 1,
      is_swap: false,
      require_format_disk: true,
      add_to_linux_fstab: true,
      file_system: 'ext3',
      hot_attach: 0
    }
  end

  def mount_point
    primary ? '/' : @mount_point
  end

  def disk_size_on_vm
    wait_until(60) do
      command = SshCommands::OnVirtualServer.disk_size(mount_point, is_swap)
      size = @virtual_machine.ssh_execute(command).last.to_f/1024/1024
      size > 0 ? size : false
    end
  end

  def disk_size_compare_with_interface
    disk_size_inside_vm = disk_size_on_vm.to_f
    disk_size_minus_ratio = disk_size - (disk_size.to_f * @acceptable_physycal_error_ratio)
    disk_size_plus_ratio = disk_size + (disk_size.to_f * @acceptable_physycal_error_ratio)
    if disk_size_inside_vm >= disk_size_minus_ratio && disk_size_inside_vm <= disk_size_plus_ratio
      Log.info("disk size inside VM: #{disk_size_inside_vm} in comparing with disk size in UI: #{disk_size} should be between acceptable values: #{disk_size_minus_ratio} and #{disk_size_plus_ratio}")
      true
    else
      Log.warn("disk size inside VM: #{disk_size_inside_vm} in comparing with disk size in UI: #{disk_size} should be between acceptable values: #{disk_size_minus_ratio} and #{disk_size_plus_ratio}")
      false
    end
  end

  def autobackup(status = 'enable')
    interface.post("/settings/disks/#{id}/autobackup_#{status}")
  end

  def unlock
    interface.post("/settings/disks/#{@id}/unlock")
  end

  def locked?
    info_update.locked
  end

  def create_backup
    backup = Backup.new(self).create
  end
end