require 'helpers/transaction'
require 'timeout'

module DiskOperationsWaiters
  include Transaction

  def wait_for_build
    @test.wait_for_transaction(id, 'Disk', 'build_disk')
    self.info_update
  end
  def wait_for_provision
    @test.wait_for_transaction(id, 'Disk', 'provisioning')
    self.info_update
  end
  def wait_for_format
    @test.wait_for_transaction(id, 'Disk', 'format_disk')
    self.info_update
  end
end