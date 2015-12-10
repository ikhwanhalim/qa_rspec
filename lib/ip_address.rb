class IpAddress
  attr_reader :interface, :address, :broadcast, :created_at, :customer_network_id, :disallowed_primary, :gateway, :hypervisor_id,
              :id, :ip_address_pool_id, :network_address, :network_id, :pxe, :updated_at, :user_id, :free, :netmask,
              :join_id

  def initialize(interface, ip_address_route)
    @interface = interface
    @ip_address_route = ip_address_route
  end

  def info_update(join)
    @join_id = join.id
    join.ip_address.each { |k,v| instance_variable_set("@#{k}", v) }
    @ip_address_join_route = "#{@ip_address_route}/#{join.id}"
    self
  end

  def attach(network_interface_id)
    interface.post(@ip_address_route, {ip_address_join: {network_interface_id: network_interface_id}})
  end

  def detach(rebuild_network = false)
    interface.delete("#{@ip_address_route}/#{join_id}", {ip_address_join: {rebuild_network: rebuild_network}})
  end
end