module VmFirewall
  attr_reader :firewall_rules

  #By default select primary network interface
  def create_firewall_rule(data = {port: nil, address: nil, command: 'ACCEPT', protocol: 'TCP'})
    data[:network_interface_id] ||= network_interfaces.first['network_interface']['id']
    post("/virtual_machines/#{identifier}/firewall_rules", {firewall_rule: data})
  end

  def update_firewall_rules
    @firewall_rules = post("/virtual_machines/#{identifier}/update_firewall_rules")
    wait_for_update_custom_firewall_rule
    @firewall_rules
  end

  def delete_firewall_rule(id)
    delete("/virtual_machines/#{identifier}/firewall_rules/#{id}")
  end

  def edit_firewall_rule(id, data={})
    post("/virtual_machines/#{identifier}/firewall_rules/#{id}", {firewall_rule: data})
  end
end