class NetworkGroup
  attr_reader :interface, :id, :label, :server_type, :location_group_id, :preconfigured_only, :hypervisor_id,:errors

  def initialize(interface)
    @interface = interface
    @location_group = interface.location_group
  end

  def create(**params)
    response = interface.post('/settings/network_zones', { network_group: build_data.merge(params) })
    response_handler response
  end

  def build_data
    {
        label: "NetworkZone_#{SecureRandom.hex(4)}",
        server_type: 'virtual',
        location_group_id: @location_group.id,
    }
  end

  def edit(params)
    response = interface.put(route, { network_group: params })
    response_handler response
  end

  def remove
    interface.delete(route)
    Log.error("Network Zone with id #{id} has not been deleted") if api_response_code != '204'
  end

  def attach_network(network_id)
    interface.post("#{route}/networks/#{network_id}/attach")
  end

  def route
    "/settings/network_zones/#{id}"
  end

  def api_response_code
    interface.conn.page.code
  end

  def response_handler(response)
    @errors = response['errors']
    network_zone = if response['network_group']
                         response['network_group']
                       elsif !@errors
                         interface.get(route)['network_group']
                       end
    return Log.warn(@errors) if @errors
    network_zone.each { |k, v| instance_variable_set("@#{k}", v)}
  end
end