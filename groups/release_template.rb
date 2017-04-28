class ReleaseTemplate
  include ApiClient, SshClient, Log, Mysql

  attr_accessor :hypervisor, :template
  attr_reader   :virtual_machine, :backup_server, :settings

  def interface
    self
  end

  def precondition
    @settings = Settings.new(self)
    @template = ImageTemplate.new(self)
    @template.find_by_manager_id(ENV['TEMPLATE_MANAGER_ID'])

    @backup_server = BackupServer.new(self)
    @backup_server.find_first_active

    @hypervisor = Hypervisor.new(self)
    @hypervisor.find_by_virt(ENV['VIRT_TYPE'])

    @virtual_machine = VirtualServer.new(self)
    @virtual_machine.create

    self
  end
end