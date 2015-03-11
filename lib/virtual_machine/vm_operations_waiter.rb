require 'helpers/transaction'

module VmOperationsWaiters
  include Transaction  
  
  def wait_for_configure_operating_system
    wait_for_transaction(@virtual_machine['id'], 'VirtualMachine', 'configure_operating_system')
  end
  def wait_for_start
    set_max_mem
    wait_for_transaction(@virtual_machine['id'], 'VirtualMachine', 'startup_virtual_machine')
  end
  def wait_for_provision_freebsd
    wait_for_transaction(@virtual_machine['id'], 'VirtualMachine', 'provision_freebsd')
  end
  def wait_for_provision_win
    wait_for_transaction(@virtual_machine['id'], 'VirtualMachine', 'provision_win')
  end
  def wait_for_stop
    wait_for_transaction(@virtual_machine['id'], 'VirtualMachine', 'stop_virtual_machine')
  end
  def wait_for_destroy
    wait_for_transaction(@virtual_machine['id'], 'VirtualMachine', 'destroy_virtual_machine')
  end
  def wait_for_reboot
    set_max_mem
    wait_for_transaction(@virtual_machine['id'], 'VirtualMachine', 'reboot_virtual_machine')
  end
  def wait_for_resize_without_reboot
    wait_for_transaction(@virtual_machine['id'], 'VirtualMachine', 'resize_vm_without_reboot')
  end
  def wait_for_resize
    set_max_mem
    wait_for_transaction(@virtual_machine['id'], 'VirtualMachine', 'resize_virtual_machine')
  end
  def set_max_mem
    @maxmem = @virtual_machine['memory']*2 if @hypervisor['hypervisor_type'] == 'xen'
    @maxmem = @virtual_machine['memory'] if @hypervisor['hypervisor_type'] == 'kvm'
  end
end