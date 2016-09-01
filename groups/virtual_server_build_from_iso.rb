class IsoVirtualServerActions
  include FogOnapp, ApiClient, SshClient, Log

  attr_accessor :hypervisor, :iso
  attr_reader   :virtual_machine
  alias template iso

  def precondition
    @hypervisor = Hypervisor.new(self)
    @hypervisor.find_by_virt(ENV['VIRT_TYPE'])
    return false unless @hypervisor.is_data_mounted?

    @iso = Iso.new(self)
    @iso.create
    @iso.make_public

    @template_store = @iso.add_to_template_store(@iso.id, 0)

    @virtual_machine = VirtualServer.new(self)
    @virtual_machine.create

    self
  end
end
