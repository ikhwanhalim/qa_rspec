require_relative 'transaction'

module DiskOperationsWaiters
  include Transaction

  def wait_for_build
    wait_for_transaction(id, 'Disk', 'build_disk')
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
end