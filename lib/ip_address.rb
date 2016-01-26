class IpAddress
  include Network

  attr_reader :interface, :network_interface, :address, :broadcast, :created_at, :customer_network_id,
              :disallowed_primary, :gateway, :hypervisor_id, :id, :ip_address_pool_id, :network_address, :network_id,
              :pxe, :updated_at, :user_id, :free, :netmask, :join_id

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

  def attach(network_interface_id, ip_address_id)
    data = {
      ip_address_join: {
        network_interface_id: network_interface_id,
        ip_address_id: ip_address_id
      }
    }
    join = interface.post(@ip_addresses_route, data)
    return if join.errors
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

  def private?
    IPAddress(address).private?
  end
end