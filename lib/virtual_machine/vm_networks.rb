require 'net/ping'
require 'socket'
require 'timeout'

module VmNetwork

  def ssh_port_opened(network_interface = 1, ip_address_number = 1)
    ip_address = ip(network_interface, ip_address_number)
    Log.info("IP address is: #{ip_address}")
    if is_port_opened?(ip: ip_address, port: 22)
      return true
    else
      Log.error ("No SSH responce from #{ip_address}")
    end
  end

  def is_port_opened?(ip: ip, port: 22, time: 300)
    Log.info("Connect to: #{ip}:#{port}")
    Timeout::timeout(time) do
      begin
        s = TCPSocket.new(ip, port)
        s.close
        return true
      rescue Errno::ETIMEDOUT, Errno::ECONNREFUSED, Errno::EHOSTUNREACH
        retry
      end
    end
    rescue Timeout::Error
      return false
  end

  def pinged?(network_interface: 1, ip_address_number: 1, attemps: 30)
    ip_address = ip(network_interface, ip_address_number)
    Log.info("Ping IP address: #{ip_address}")
    host = Net::Ping::External.new(ip_address)
    attemps.times { return true if host.ping?; sleep 1 }
    false
  end

  def ip(network_interface = 1, ip_address_number = 1)
    network_interface = if network_interface == 1
      @network_interfaces.select {|t| t['network_interface']['primary'] }
    else
      @network_interfaces.select {|t| !t['network_interface']['primary'] }
    end.first
    ip_address = @ip_addresses.select {|ip| ip['ip_address_join']['network_interface_id'] == network_interface['network_interface']['id'] }
    ip_address = ip_address[ip_address_number - 1]
    ip_address['ip_address_join']['ip_address']['address']
  end

  def rebuild_network(**params)
    data = params || { is_shutdown_required: true, shutdown_type: 'graceful', required_startup: 1 }
    post("#{@route}/rebuild_network", data)
    return false if api_response_code  == '404'
    wait_for_rebuild_network
  end
end