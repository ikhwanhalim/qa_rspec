class IpAddress
  attr_reader :address, :broadcast, :created_at, :customer_network_id, :disallowed_primary, :gateway, :hypervisor_id,
              :id, :ip_address_pool_id, :network_address, :network_id, :pxe, :updated_at, :user_id, :free, :netmask,
              :join_id
  def initialize(interface, ip_address_join_route)
    @interface = interface
    @ip_address_join_route = ip_address_join_route
  end

  def info_update(info = false)
    info = interface.get(@ip_address_join_route)if !info
    @join_id = info.id
    info.ip_address.each { |k,v| instance_variable_set("@#{k}", v) }
    @ip_address_join_route = "#{@ip_address_join_route}/#{@join_id}"
    self
  end
end