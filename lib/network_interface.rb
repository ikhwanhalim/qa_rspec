require 'virtual_server_ip_address'

class NetworkInterface
  attr_reader :compute, :connected, :created_at, :default_firewall_rule, :id, :identifier, :label, :mac_address, :network_join_id,
              :primary, :rate_limit, :updated_at, :usage, :usage_last_reset_at, :usage_month_rolled_at, :virtual_machine_id
  def initialize(compute, vm_route)
    @compute = compute
    @vm_route = vm_route
  end
  def info_update(info = false)
    info = compute.get(@route)if !info
    info.each { |k,v| instance_variable_set("@#{k}", v) }
    @route = "/settings/network_interfaces/#{id}"
    ip_addresses_info_update
    self
  end

  def ip_addresses_info_update
    ip_address_route = "#{@vm_route}/ip_addresses"
    @ip_addresses = []
    compute.get(ip_address_route).each do |ip_join|
      if ip_join.ip_address_join.network_interface_id.to_s == id.to_s
        @ip_addresses << VirtualServerIpAddress.new(compute, ip_address_route).info_update(ip_join.ip_address_join)
      end
    end
  end

  def ip_address(order_number = 1)
    if @ip_addresses.any?
      @ip_addresses[order_number-1]
    else
      Log.error("There is no ip addresses associated with #{@route} network interface")
    end
  end
end