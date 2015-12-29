class Disk
  include DiskOperationsWaiters, Waiter
  attr_reader :interface, :add_to_freebsd_fstab, :add_to_linux_fstab,:built,:burst_bw,:burst_iops,:created_at,:data_store_id,
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

  def info_update(info=false)
    info ||= interface.get(@route)
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

  def remove
    interface.delete(@route)
    return if interface.conn.page.code != '204'
    wait_for_destroy
  end

  def build_params
    {
      label: "Disk-#{SecureRandom.hex(4)}",
      disk_size: 1,
      is_swap: false,
      require_format_disk: true,
      add_to_linux_fstab: true,
      file_system: 'ext3'
    }
  end

  def mount_point
    primary ? '/' : @mount_point
  end

  def disk_size_on_vm
    command = SshCommands::OnVirtualServer.disk_size(mount_point)
    @virtual_machine.ssh_execute(command).first.to_f
  end

  def disk_size_compare_with_interface
    disk_size_inside_vm=disk_size_on_vm.to_f
    disk_size_minus_ratio=disk_size-(disk_size.to_f*@acceptable_physycal_error_ratio)
    disk_size_plus_ratio=disk_size+(disk_size.to_f*@acceptable_physycal_error_ratio)
    Log.info("disk size inside VM: #{disk_size_inside_vm} in comparing with disk size in UI: #{disk_size} should be between acceptable values: #{disk_size_minus_ratio} and #{disk_size_plus_ratio}")
     return true if disk_size_inside_vm >= disk_size_minus_ratio and disk_size_inside_vm <= disk_size_plus_ratio
    Log.error("disk size inside VM: #{disk_size_inside_vm} in comparing with disk size in UI: #{disk_size} should be between acceptable values: #{disk_size_minus_ratio} and #{disk_size_plus_ratio}")
     false
  end
end