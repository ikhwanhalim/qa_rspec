class IpAddress
  include NetworkCommands

  attr_reader :interface, :network_interface, :address, :broadcast, :created_at, :customer_network_id,
              :disallowed_primary, :gateway, :hypervisor_id, :id, :ip_address_pool_id, :network_address, :network_id,
              :pxe, :updated_at, :user_id, :free, :netmask, :join_id, :ip_range_id, :ip_net_id

  alias ip_address address

  def initialize(network_interface)
    @interface = network_interface.interface
    @network_interface = network_interface
    @ip_addresses_route = network_interface.ip_addresses_route
  end

  def info_update(join)
    @join_id = join.id
    join.ip_address.each { |k,v| instance_variable_set("@#{k}", v) }
    @ip_address_join_route = "#{@ip_addresses_route}/#{join.id}"
    self
  end

  def attach(network_interface_id, ip_address_id=nil, used_ip=0, address=nil)
    if interface.version < 5.4
      data = {
          ip_address_join: {
              network_interface_id: network_interface_id,
              ip_address_id: ip_address_id,
              used_ip: used_ip
          }
      }
    else
      data = {
          ip_address: {
              network_interface_id: network_interface_id,
              address: address,
              used_ip: used_ip
          }
      }
    end
    join = interface.post(@ip_addresses_route, data)
    return join.errors if join.errors
    info_update(join.ip_address_join)
  end

  def detach(rebuild_network = false)
    interface.delete(@ip_address_join_route, {ip_address_join: {rebuild_network: rebuild_network}})
  end

  def exist_on_vm
    command = SshCommands::OnVirtualServer.ip_addresses
    network_interface.virtual_machine.ssh_execute(command).include?(address)
  end

  def all(used: false)
    interface.get("/settings/networks/#{network_id}/ip_addresses").select do |ip|
      used ? ip.ip_address.free == false : ip.ip_address.free == true
    end
  end

  def used_ips
    @used_ips ||=
      interface.get("/settings/networks/#{network_id}/ip_addresses").inject([]) do |used_ips, ip|
        used_ips << IPAddr.new(ip.ip_address['address']).to_i
    end
  end

  def user_used_ips(vm)
    profile_page = vm.network_interface.ip_address.interface.conn.page.body
    own_ips = profile_page.map {|ip_addr| ip_addr.ip_address_join.ip_address.address}
    ip_range_ids = profile_page.map {|ip_addr| ip_addr.ip_address_join.ip_address.ip_net_id}

    @user_used_ips =
        interface.get("/profile").user.used_ip_addresses.each_with_object([]) do |ip, user_used_ips|
          if ip_range_ids.include?(ip.ip_address.ip_range_id)
            user_used_ips << ip.ip_address.address unless own_ips.include?(ip.ip_address.address)
          end
        end
  end

  def free_ip
    ip_range = IpRange.new(self).get(network_id, ip_net_id, ip_range_id)
    start_address = IPAddr.new(ip_range.start_address).to_i
    end_address = IPAddr.new(ip_range.end_address).to_i
    (start_address..end_address).each { |ip| return IPAddr.new(ip, Socket::AF_INET).to_s unless used_ips.include?(ip) }
  end

  def private?
    IPAddress(address).private?
  end
end