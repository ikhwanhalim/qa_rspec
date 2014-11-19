require 'helpers/transaction'

module VmOperationsWaiters
  include Transaction  
  
  def wait_for_configure_operaiong_system
    wait_for_transaction(@id, 'VirtualMachine', 'configure_operating_system')
  end
  def wait_for_start
    wait_for_transaction(@id, 'VirtualMachine', 'startup_virtual_machine')
  end
  def wait_for_provision_freebsd
    wait_for_transaction(@id, 'VirtualMachine', 'provision_freebsd')
  end
  def wait_for_provision_win
    wait_for_transaction(@id, 'VirtualMachine', 'provision_win')
  end
  def wait_for_stop
    wait_for_transaction(@id, 'VirtualMachine', 'stop_virtual_machine')
  end
  def wait_for_destroy
    wait_for_transaction(@id, 'VirtualMachine', 'destroy_virtual_machine')
  end
  def wait_for_reboot
    wait_for_transaction(@id, 'VirtualMachine', 'reboot_virtual_machine')
  end
end