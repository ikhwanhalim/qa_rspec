module VmIpAddress
  attr_reader :ip_addresses

  def ip_addresses
    @ip_addresses = get("#{@route}/ip_addresses")
  end

  def primary_network_interface_id
    network_interfaces.map do |i|
      i['network_interface']['id'] if i['network_interface']['primary']
    end.compact.first
  end

  def allocate_new_ip
    data = {ip_address_join: {network_interface_id: primary_network_interface_id}}
    post("#{@route}/ip_addresses", data)
    return false if api_response_code == '404'
    wait_for_update_firewall
    rebuild_network
    old_ips = @ip_addresses
    wait_until do
      diff = ip_addresses - old_ips
      diff.any? ? diff.first['ip_address_join'] : false
    end rescue
      Log.error('Ip has not been added')
  end

  def delete_ip(id, rebuild_network = true)
    delete("#{@route}/ip_addresses/#{id}", {rebuild_network: rebuild_network})
    rebuild_network ? wait_for_rebuild_network : wait_for_update_firewall
    old_ips = @ip_addresses
    wait_until do
      diff = old_ips - ip_addresses
      diff.any? ? diff.first['ip_address_join'] : false
    end rescue
      Log.error('Ip has not been removed')
  end
end