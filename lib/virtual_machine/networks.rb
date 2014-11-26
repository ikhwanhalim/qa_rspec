#require 'helpers/onapp_ssh'

module VmNetwork
  #include OnappSSH
  
  def ssh_port_opened(network_interface = 1, ip_address_number = 1)
    ip_address = ip(network_interface, ip_address_number)
    attempts = 12
    while `nc -z #{ip_address} 22 -w1 || echo false`.include?('false')
      if attempts < 0
        return false
      end      
      attempts-=1
      sleep 10
    end        
    true
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