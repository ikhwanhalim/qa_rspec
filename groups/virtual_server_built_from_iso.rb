class IsoVirtualServerActions
  include ApiClient, SshClient, Log

  IDENTIFIER = ENV['IDENTIFIER']
  ISO_ID     = ENV['ISO_ID']

  attr_accessor :hypervisor, :iso
  attr_reader   :virtual_machine, :settings
  alias template iso

  def precondition
    @hypervisor = Hypervisor.new(self)
    @hypervisor.find_by_virt(ENV['VIRT_TYPE'])
    return false unless @hypervisor.is_data_mounted?

    @iso = Iso.new(self)
    if ISO_ID
      @iso.find(ISO_ID)
    else
      @iso.create(min_memory_size: 512, min_disk_size: 6)
    end
    @iso.make_public

    @template_store = @iso.add_to_template_store(@iso.id, 0)

    @virtual_machine = VirtualServer.new(self)
    if IDENTIFIER
      @virtual_machine.find(IDENTIFIER)
    else
      @virtual_machine.create
    end

    @settings = Settings.new(self)

    self
  end
end
