class GroupActions
  include ApiClient, Log

  attr_reader :location_group, :hypervisor_group, :hypervisor, :network_group, :data_store_group

  def precondition
    @location_group = LocationGroup.new(self)
    @hypervisor = Hypervisor.new(self)
    @location_group.select_location_group
    @hypervisor_group = HypervisorGroup.new(self)
    @network_group = NetworkGroup.new(self)
    @data_store_group = DataStoreGroup.new(self)

    self
  end
end