require_relative 'transaction.rb'

module VmOperationsWaiters
  include Transaction

  def wait_for_configure_operating_system
    wait_for_transaction(id, 'VirtualMachine', 'configure_operating_system')
  end

  def wait_for_start
    set_max_mem
    wait_for_transaction(id, 'VirtualMachine', 'startup_virtual_machine')
  end

  def wait_for_provision_freebsd
    wait_for_transaction(id, 'VirtualMachine', 'provision_freebsd')
  end

  def wait_for_provision_win
    wait_for_transaction(id, 'VirtualMachine', 'provision_win')
  end
  def wait_for_provision_virtual_machine
    wait_for_transaction(id, 'VirtualMachine', 'provision_virtual_machine')
  end

  def wait_for_build_virtual_machine
    wait_for_transaction(id, 'VirtualMachine','build_virtual_machine')
  end

  def wait_for_stop
    wait_for_transaction(id, 'VirtualMachine', 'stop_virtual_machine')
  end

  def wait_for_destroy
    wait_for_transaction(id, 'VirtualMachine', 'destroy_virtual_machine')
  end

  def wait_for_reset_root_password
    wait_for_transaction(id, 'VirtualMachine', 'reset_root_password')
  end

  def wait_for_set_ssh_keys
    wait_for_transaction(id, 'VirtualMachine', 'set_ssh_keys')
  end

  def wait_for_reboot
    set_max_mem
    wait_for_transaction(id, 'VirtualMachine', 'reboot_virtual_machine')
  end

  def wait_for_resize_without_reboot
    wait_for_transaction(id, 'VirtualMachine', 'resize_vm_without_reboot')
  end

  def wait_for_resize
    set_max_mem
    wait_for_transaction(id, 'VirtualMachine', 'resize_virtual_machine')
  end

  def wait_for_hot_migration
    wait_for_transaction(id, 'VirtualMachine', 'hot_migrate')
  end

  def wait_for_cold_migration
    wait_for_transaction(id, 'VirtualMachine', 'cold_migrate')
  end

  def wait_for_run_recipe_on_vm
    wait_for_transaction(id, 'VirtualMachine', 'run_recipe_on_vm')
  end

  #VmNetwork
  def wait_for_update_update_rate_limit
    wait_for_transaction(network_interface_id, 'NetworkInterface', 'update_rate_limit')
  end
  def wait_for_update_firewall
    wait_for_transaction(network_interface_id, 'NetworkInterface', 'update_firewall')
  end

  def wait_for_attach_network_interface
    wait_for_transaction(network_interface_id, 'NetworkInterface', 'attach_network_interface')
  end

  def wait_for_detach_network_interface
    wait_for_transaction(network_interface_id, 'NetworkInterface', 'detach_network_interface')
  end

  def wait_for_update_custom_firewall_rule
    wait_for_transaction(id, 'VirtualMachine', 'update_custom_firewall_rule')
  end

  def wait_for_rebuild_network
    wait_for_transaction(id, 'VirtualMachine', 'rebuild_network')
  end

  def wait_for_run_recipes_on_server
    wait_for_transaction(id, 'VirtualMachine', 'run_recipe_on_vm')
  end

  def wait_for_enable_auto_scaling
    wait_for_transaction(id, 'VirtualMachine', 'enable_auto_scaling')
  end

  def wait_for_check_or_install_zabbix_agent
    wait_for_transaction(id, 'VirtualMachine', 'check_or_install_zabbix_agent')
  end

  def wait_for_building_backups
    begin
      wait_until { building_backups_exist? }
    rescue Timeout::Error
      return false
    end
    wait_until(10800, 10) { !building_backups_exist? }
  end
  def wait_for_upload_ova
    wait_for_transaction(id, 'VirtualMachine', 'upload_ova')
  end

  def building_backups_exist?
    backups = interface.get("/users/#{user_id}/backups").map &:backup
    backups.select { |b| b.built == false }.any?
  end

  #FederationTrader
  def wait_for_receive_notification_from_market
     wait_for_transaction(id, 'VirtualMachine', 'receive_notification_from_market')
  end

  def set_max_mem
    maxmem = if interface.hypervisor.hypervisor_type == 'xen'
               memory * 2
             elsif interface.hypervisor.hypervisor_type == 'kvm'
               memory
             end
  end
end