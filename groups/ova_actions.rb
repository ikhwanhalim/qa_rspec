class OvaActions
  include ApiClient, Log, SshClient

  attr_reader :ova, :backup_server

  def precondition
    @backup_server = BackupServer.new(self)
    @backup_server.find_suitable_for_ova
    return false unless @backup_server.is_data_mounted?
    @ova = Ova.new(self)
    @ova.create

    self
  end
end