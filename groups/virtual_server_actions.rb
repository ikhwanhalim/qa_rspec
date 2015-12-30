class VirtualServerActions
  include FogOnapp, ApiClient, SshClient, TemplateManager, Log

  attr_accessor :hypervisor, :template
  attr_reader   :virtual_machine, :iso

  def precondition
    @iso = Iso.new(self)
    @iso.create

    @template = ImageTemplate.new(self)
    @template.find_by_manager_id(ENV['TEMPLATE_MANAGER_ID'])

    @hypervisor = Hypervisor.new(self)
    @hypervisor.find_by_virt(ENV['VIRT_TYPE'])

    @virtual_machine = VirtualServer.new(self)
    @virtual_machine.create
    #if needed run test separately on existed VM uncomment string below and comment all other strings except @virtual_machine = VirtualServer.new(self)
    #@virtual_machine.find('wqic27fq6kz3fc')

    self
  end
end