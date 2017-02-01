class HypervisorGroup
  attr_reader :interface, :id, :label, :server_type, :location_group_id, :preconfigured_only, :run_sysprep,
              :cpu_flags_enabled, :errors

  def initialize(interface, location_group= nil)
    @interface = interface
    @location_group = location_group
  end


  def create(**params)
    response = interface.post('/settings/hypervisor_zones', { hypervisor_group: build_data.merge(params) })
    response_handler response
  end

  def build_data
    {
      label: "ComputeZone_#{SecureRandom.hex(4)}",
      server_type: 'virtual',
      location_group_id: (@location_group.id if @location_group),
      run_sysprep: 1,
      cpu_flags_enabled: false
    }
  end

  def edit(params)
    response = interface.put(route, { hypervisor_group: params })
    response_handler response
  end

  def remove
    interface.delete(route)
    Log.error("Hypervizor Zone with id #{id} has not been deleted") if api_response_code != '204'
  end

  def attach_hypervisor(hypervisor_id)
    interface.post("#{route}/hypervisors/#{hypervisor_id}/attach")
  end

  def route
    "/settings/hypervisor_zones/#{id}"
  end

  def api_response_code
    interface.conn.page.code
  end

  def response_handler(response)
    @errors = response['errors']
    hypervisor_group = if response['hypervisor_group']
                           response['hypervisor_group']
                         elsif !@errors
                           interface.get(route)['hypervisor_group']
                         end
    return Log.warn(@errors) if @errors
    hypervisor_group.each { |k, v| instance_variable_set("@#{k}", v)}
  end
end