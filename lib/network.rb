class Network
  attr_reader :interface, :id, :label, :identifier, :network_group_id

  def initialize(interface)
    @interface = interface
  end

  def get(id: id)
    info_update interface.get("#{route}/#{id}")
  end

  def create(**params)
    info_update interface.post(route, {network: build_data.merge(params) })
  end

  def build_data
    {
        label: "Network_#{SecureRandom.hex(4)}",
        vlan: 123,
        type: "Networking::Network"
    }
  end

  def edit(params)
    info_update interface.put(route, { network_group: params })
  end

  def remove
    interface.delete("#{route}/#{id}")
  end

  def route
    "/networking/api/networks"
  end


  def info_update(response)
    return Log.warn(response['errors']) if response['errors']
    network = response['network'] if response['network']
    network.each { |k, v| instance_variable_set("@#{k}", v)}
  end
end