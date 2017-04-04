class IpNet
  attr_reader :interface, :id, :network_id, :network_address, :network_mask, :label

  def initialize(network)
    @interface = network.interface
    @network_id = network.id
  end

  def create(**params)
    binding.pry
    info_update interface.post(route, {ip_net: build_data.merge(params) })
  end

  def route
    "/networking/api/ip_nets"
  end

  def build_data
    {
        label: "IPNet_#{SecureRandom.hex(4)}",
        network_id: network_id,
        network_address: "%d.%d.%d.%d" % [rand(256), rand(256), 0, 0],
        network_mask: 24,
        add_default_ip_range: 0
    }
  end

  def remove
    interface.delete("#{route}/#{id}")
  end

  def info_update(response)
    return Log.warn(response['errors']) if response['errors']
    ip_net = response['ip_net'] if response['ip_net']
    ip_net.each { |k, v| instance_variable_set("@#{k}", v)}
  end
end