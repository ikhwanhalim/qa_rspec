class IpRange
  attr_reader  :interface, :id, :start_address, :end_address, :default_gateway, :ipv4

  def initialize(ip_net)
    @interface = ip_net.interface
  end

  def get(network_id, ip_net_id, ip_range_id)
    info_update interface.get("/settings/networks/#{network_id}/ip_nets/#{ip_net_id}/ip_ranges/#{ip_range_id}")
  end

  def info_update(response)
    return Log.warn(response['errors']) if response['errors']
    ip_range = response['ip_range'] if response['ip_range']
    ip_range.each { |k, v| instance_variable_set("@#{k}", v)}
  end
end