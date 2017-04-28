class VirtualServerActions
  include ApiClient, SshClient, Log

  IDENTIFIER          = ENV['IDENTIFIER']
  TEMPLATE_MANAGER_ID = ENV['TEMPLATE_MANAGER_ID']
  OPERATING_SYSTEM    = ENV['OPERATING_SYSTEM']
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
      OPERATING_SYSTEM ? @template.find_by_manager_id(operating_system: OPERATING_SYSTEM) : @template.find_by_manager_id(manager_id:TEMPLATE_MANAGER_ID)

      @hypervisor = Hypervisor.new(self)
      @hypervisor.find_by_virt(VIRT_TYPE)

      @virtual_machine.create(domain: 'autotest.qa.com')
    end

    self
  end
end