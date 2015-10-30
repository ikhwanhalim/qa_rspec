class Disk
  include DiskOperationsWaiters
  attr_reader :interface, :add_to_freebsd_fstab, :add_to_linux_fstab,:built,:burst_bw,:burst_iops,:created_at,:data_store_id,
              :disk_size,:disk_vm_number,:file_system,:id,:identifier, :iqn,:is_swap, :label,:locked,:max_bw,
              :max_iops, :min_iops, :mount_point, :primary, :updated_at,:virtual_machine_id, :volume_id,:has_autobackups

  def initialize(interface)
    @interface = interface
  end

  def data_store_identifier
    interface.get("/settings/data_stores/#{data_store_id}").data_store.identifier
  end

  def info_update(info = false)
    info = interface.get(@route) unless info
    info.each { |k,v| instance_variable_set("@#{k}", v) }
    @route = "/settings/disks/#{id}"
    self
  end
end