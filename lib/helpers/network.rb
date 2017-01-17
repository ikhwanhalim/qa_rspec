require_relative 'waiter'

module Network
  include Waiter

  def port_opened?(remote_ip: ip_address, port: 22)
    wait_until do
      exit_ok? ssh_command(remote_ip, port)
    end
  end

  def port_closed?(remote_ip: ip_address, port: 22)
    wait_until do
      !exit_ok? ssh_command(remote_ip, port)
    end
  end

  def pinged?(remote_ip: ip_address)
    wait_until do
      exit_ok? ping_command(remote_ip)
    end
  end

  def not_pinged?(remote_ip: ip_address)
    wait_until do
      !exit_ok? ping_command(remote_ip)
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
    interface.run_on_cp(command)
  end

  def ping_command(remote_ip)
    SshCommands::OnControlPanel.ping(remote_ip)
  end

  def ssh_command(remote_ip, port)
    SshCommands::OnControlPanel.nc(remote_ip, port)
  end
end
