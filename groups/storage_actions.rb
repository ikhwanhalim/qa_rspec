class StorageActions
  include ApiClient, SshClient, Log

  VIRT_TYPE = ENV['VIRT_TYPE']

  attr_accessor :hypervisor, :storage_disk, :settings

  def precondition
    @settings = Settings.new(self)
    @hypervisor = Hypervisor.new(self)
    @hypervisor.find_by_virt(VIRT_TYPE)
    @storage_disk = StorageDisk.new(self)
    @virtual_server = VirtualServer.new(self)
    self
  end
end