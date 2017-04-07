class IpRange
  attr_reader  :interface, :id, :start_address, :end_address, :default_gateway, :ipv4

  def initialize(ip_net)
    @interface = ip_net.interface
  end

  def get(id)
    info_update interface.get("/networking/api/ip_ranges/#{id}")
  end

  def info_update(response)
    return Log.warn(response['errors']) if response['errors']
    ip_range = response['ip_range'] if response['ip_range']
    ip_range.each { |k, v| instance_variable_set("@#{k}", v)}
  end
end