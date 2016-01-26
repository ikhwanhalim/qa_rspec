require_relative 'waiter'

module Network
  include Waiter

  def port_opened?(remote_ip = ip_address, port = 22)
    wait_until do
      command = SshCommands::OnControlPanel.nc(remote_ip, port)
      exit_ok?(command) ? true : false
    end
  end

  def port_closed?(remote_ip = ip_address, port = 22)
    wait_until do
      command = SshCommands::OnControlPanel.nc(remote_ip, port)
      exit_ok?(command) == 0 ? false : true
    end
  end

  def pinged?(remote_ip = ip_address)
    wait_until do
      command = SshCommands::OnControlPanel.ping(remote_ip)
      exit_ok?(command) ? true : false
    end
  end

  def not_pinged?(remote_ip = ip_address)
    wait_until do
      command = SshCommands::OnControlPanel.ping(remote_ip)
      exit_ok?(command) ? false : true
    end
  end

  def up?
    pinged? && port_opened?
  end

  def down?
    not_pinged? && port_closed?
  end

  private

  def exit_ok?(command)
    interface.execute_with_pass({'vm_host' => interface.ip, 'vm_user' => 'onapp'}, command).last.to_i == 0
  end
end