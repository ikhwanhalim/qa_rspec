class IsoVirtualServerActions
  include FogOnapp, ApiClient, SshClient, Log

  attr_accessor :hypervisor, :iso
  attr_reader   :virtual_machine
  alias template iso

  def precondition

    @iso = Iso.new(self)
    @iso.create
    @iso.make_public

    @template_store = @iso.add_to_template_store(@iso.id, 0)

    @hypervisor = Hypervisor.new(self)
    @hypervisor.find_by_virt(ENV['VIRT_TYPE'])

    @virtual_machine = VirtualServer.new(self)
    return false if !@hypervisor.is_data_mounted?
    @virtual_machine.create

    self
  end
end
