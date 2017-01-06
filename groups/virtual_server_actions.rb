class VirtualServerActions
  include FogOnapp, ApiClient, SshClient, Log

  IDENTIFIER          = ENV['IDENTIFIER']
  TEMPLATE_MANAGER_ID = ENV['TEMPLATE_MANAGER_ID']
  VIRT_TYPE           = ENV['VIRT_TYPE']

  attr_accessor :hypervisor, :template, :iso, :user
  attr_reader   :virtual_machine, :settings

  def precondition
    @virtual_machine = VirtualServer.new(self)
    @settings = Settings.new(self)

    if IDENTIFIER
      @virtual_machine.find(IDENTIFIER)
    else
      @template = ImageTemplate.new(self)
      @template.find_by_manager_id(TEMPLATE_MANAGER_ID)

      @hypervisor = Hypervisor.new(self)
      @hypervisor.find_by_virt(VIRT_TYPE)

      @virtual_machine.create
    end

    self
  end
end