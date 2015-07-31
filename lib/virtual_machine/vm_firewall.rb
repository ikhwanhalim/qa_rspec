module VmFirewall
  attr_reader :firewall_rules

  def firewall_rules
    @firewall_rules = get("/virtual_machines/#{identifier}/firewall_rules")
  end

  #By default select primary network interface
  def create_firewall_rule(network_interface_id: nil, port: nil, address: nil, command: 'ACCEPT', protocol: 'TCP')
    network_interface_id ||= network_interfaces.first['network_interface']['id']
    data = { network_interface_id: network_interface_id,
             port: port.to_s,
             address: address,
             command: command,
             protocol: protocol
    }
    post("/virtual_machines/#{identifier}/firewall_rules", {firewall_rule: data})
    return false if api_response_code  == '404'
  end

  def edit_firewall_rule(id, data={})
    put("/virtual_machines/#{identifier}/firewall_rules/#{id}", {firewall_rule: data})
  end

  def update_firewall_rules
    @firewall_rules = post("/virtual_machines/#{identifier}/update_firewall_rules")
    wait_for_update_custom_firewall_rule
    info_update
    firewall_rules
  end

  def set_default_firewall_rule(command: 'ACCEPT', network_interface: 1)
    interface = if network_interface == 1
       network_interfaces.select { |ni| ni['network_interface']['primary'] }
    else
       network_interfaces.select { |ni| !ni['network_interface']['primary'] }
    end.first
    id = interface['network_interface']['id']
    data = {:network_interfaces => { id => {:default_firewall_rule => command}}}
    put("/virtual_machines/#{identifier}/firewall_rules/update_defaults", data)
    update_firewall_rules
  end

  def delete_firewall_rule(id)
    delete("/virtual_machines/#{identifier}/firewall_rules/#{id}")
    firewall_rules
  end

  def destroy_all_firewall_rules
    firewall_rules.each do |r|
      delete_firewall_rule(r['firewall_rule']['id'])
    end
    update_firewall_rules if firewall_rules.any?
  end
end