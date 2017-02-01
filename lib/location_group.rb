class LocationGroup
  attr_reader :interface, :id, :federated, :cdn_enabled

  def initialize(interface)
    @interface = interface
  end

  def get_all_attached_hypervisor_groups
    interface.get("/settings/location_groups/#{id}/hypervisor_groups")
  end

  def select_location_group
    location_group = interface.get('/settings/location_groups').map(&:location_group).first
    return Log.warn('There is no locations in this cloud') unless location_group
    response_handler(location_group)
  end

  def response_handler(response)
    response.each { |k, v| instance_variable_set("@#{k}", v)}
  end
end