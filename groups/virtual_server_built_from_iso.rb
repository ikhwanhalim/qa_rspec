class IsoVirtualServerActions
  include FogOnapp, ApiClient, SshClient, Log

  attr_accessor :hypervisor, :iso
  attr_reader   :virtual_machine, :settings
  alias template iso

  def precondition
    @hypervisor = Hypervisor.new(self)
    @hypervisor.find_by_virt(ENV['VIRT_TYPE'])
    return false unless @hypervisor.is_data_mounted?

    @iso = Iso.new(self)
    @iso.create(min_memory_size: 256, min_disk_size: 6)
    @iso.make_public

    @template_store = @iso.add_to_template_store(@iso.id, 0)

    @virtual_machine = VirtualServer.new(self)
    @virtual_machine.create

    @settings = Settings.new(self)

    self
  end
end
