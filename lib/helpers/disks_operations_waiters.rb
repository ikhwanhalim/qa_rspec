require_relative 'transaction'

module DiskOperationsWaiters
  include Transaction

  def wait_for_build
    wait_for_transaction(id, 'Disk', 'build_disk')
    info_update
  end

  def wait_for_attach
    wait_for_transaction(id, 'Disk', 'attach_disk')
    info_update
  end

  def wait_for_provision
    wait_for_transaction(id, 'Disk', 'provisioning')
    info_update
  end

  def wait_for_format
    wait_for_transaction(id, 'Disk', 'format_disk')
    info_update
  end

  def wait_for_destroy
    wait_for_transaction(id, 'Disk', 'destroy_disk')
  end

  def wait_for_detach
    wait_for_transaction(id, 'Disk', 'detach_disk')
  end

  def wait_for_resize
    wait_for_transaction(id, 'Disk', 'resize_disk')
    info_update
  end

  def wait_for_disk_migrate
    wait_for_transaction(id, 'Disk', 'migrate_disk')
    info_update
  end

  def wait_for_update_fstab
    wait_for_transaction(id, 'Disk', 'update_fstab')
    info_update
  end

  def wait_for_lock
    wait_until { locked? }
  end

  def wait_for_repair_vdisk(parent_id)
    wait_for_transaction(parent_id, "Storage::Repair", "repair_disk")
  end

  def wait_for_rebalance_vdisk(parent_id)
    wait_for_transaction(parent_id, "Storage::Repair", "rebalance_disk")
  end
end