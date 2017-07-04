require_relative 'transaction.rb'

module CpOperationsWaiters
  include Transaction

  def wait_update_configuration
    wait_for_transaction(nil, nil, 'update_configuration')
  end

  def wait_configure_hypervisor_messaging
    wait_for_transaction(nil, nil, 'configure_hypervisor_messaging')
  end
end