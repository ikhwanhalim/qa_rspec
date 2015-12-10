class NetworkInterface
  include VmOperationsWaiters

  attr_reader :interface, :ip_addresses, :connected, :created_at, :default_firewall_rule, :id, :identifier, :label, :mac_address, :network_join_id,
              :primary, :rate_limit, :updated_at, :usage, :usage_last_reset_at, :usage_month_rolled_at, :virtual_machine_id

  alias network_interface_id id

  def initialize(interface, vm_route)
    @interface = interface
    @vm_route = vm_route
  end

  def info_update(network_interface)
    network_interface.each { |k,v| instance_variable_set("@#{k}", v) }
    ip_addresses_info_update
    self
  end

  def ip_address_route
    "#{@vm_route}/ip_addresses"
  end

  def ip_addresses_info_update
    @ip_addresses = []
    interface.get(ip_address_route).each do |ip_join|
      if ip_join.ip_address_join.network_interface_id.to_s == id.to_s
        @ip_addresses << IpAddress.new(interface, ip_address_route).info_update(ip_join.ip_address_join)
      end
    end
  end

  def ip_address(order_number = 0)
    if @ip_addresses.any?
      @ip_addresses[order_number-1]
    else
      Log.error("There is no ip addresses associated with #{@route} network interface")
    end
  end

  def allocate_new_ip
    IpAddress.new(interface, ip_address_route).attach(id)
    wait_for_update_firewall
    ip_addresses_info_update
  end

  def remove_ip(number = 0, rebuild_network = false)
    ip_address(number).detach(rebuild_network)
    wait_for_update_firewall
    ip_addresses_info_update
  end
end