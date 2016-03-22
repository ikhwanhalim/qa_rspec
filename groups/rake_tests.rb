class RakeTests
  include FogOnapp, ApiClient, SshClient, Log

  def initialize
    conn
  end

  def run_on_cp(command)
    execute_with_keys(ip, 'onapp', command).split("\n").last.to_i.zero?
  end
end