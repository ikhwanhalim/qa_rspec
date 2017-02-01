class GroupActions
  include ApiClient, Log

  attr_reader :location_group, :hypervisor_group, :hypervisor

  def precondition
    @location_group = LocationGroup.new(self)
    @hypervisor = Hypervisor.new(self)
    @location_group.select_location_group
    @location_group ? @hypervisor_group = HypervisorGroup.new(self, location_group=@location_group) : HypervisorGroup.new(self)

    self
  end
end