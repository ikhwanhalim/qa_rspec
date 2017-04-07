class DataStoreGroup
  attr_reader :interface, :id, :label, :server_type, :location_group_id, :preconfigured_only, :errors

  def initialize(interface)
    @interface = interface
    @location_group = interface.location_group
  end

  def create(**params)
    response = interface.post('/settings/data_store_zones', { data_store_group: build_data.merge(params) })
    response_handler response
  end

  def build_data
    {
        label: "DataStoreZone_#{SecureRandom.hex(4)}",
        server_type: 'virtual',
        location_group_id: @location_group.id
    }
  end

  def edit(params)
    response = interface.put(route, { data_store_group: params })
    response_handler response
  end

  def remove
    interface.delete(route)
    Log.error("DataStore_ Zone with id #{id} has not been deleted") if api_response_code != '204'
  end

  def route
    "/settings/data_store_zones/#{id}"
  end

  def api_response_code
    interface.conn.page.code
  end

  def response_handler(response)
    @errors = response['errors']
    data_store_group = if response['data_store_group']
                         response['data_store_group']
                       elsif !@errors
                         interface.get(route)['data_store_group']
                       end
    return Log.warn(@errors) if @errors
    data_store_group.each { |k, v| instance_variable_set("@#{k}", v)}
  end

end