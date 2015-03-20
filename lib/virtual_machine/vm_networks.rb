require 'net/ping'
require 'socket'
require 'timeout'

module VmNetwork

  def ssh_port_opened(network_interface = 1, ip_address_number = 1)
    ip_address = ip(network_interface, ip_address_number)
    Log.info("IP address is: #{ip_address}")
    begin
      Timeout::timeout(300) do
        begin
          s = TCPSocket.new(ip_address, 22)
          s.close
          return true
        rescue Errno::ETIMEDOUT
          retry
        rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
          return false
        end
      end
    rescue Timeout::Error
    end
    Log.error ("No ping responce from #{ip_address}")
    return false
  end

  def pinged?(network_interface = 1, ip_address_number = 1)
    ip_address = ip(network_interface, ip_address_number)
    Log.info("Ping IP address: #{ip_address}")
    host = Net::Ping::External.new(ip_address)
    20.times { return true if host.ping?; sleep 30 }
    Log.error ("No ping responce from #{ip_address}")
    false
  end

  private
  def ip(network_interface = 1, ip_address_number = 1)
    network_interface = @network_interfaces.select {|t| t['network_interface']['primary'] } if network_interface == 1    
    network_interface = @network_interfaces.select {|t| !t['network_interface']['primary'] } if network_interface == 2    
    network_interface = network_interface.first    
    ip_address = @ip_addresses.select {|ip| ip['ip_address_join']['network_interface_id'] == network_interface['network_interface']['id'] }
    ip_address = ip_address[ip_address_number - 1]
    ip_address['ip_address_join']['ip_address']['address']
  end
end