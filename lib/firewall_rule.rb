class FirewallRule
  attr_reader :interface, :network_interface_id

  def initialize(network_interface)
    @interface = network_interface.interface
    @firewall_rules_route = network_interface.firewall_rules_route
  end

  def info_update(rule=nil)
    rule ||= interface.get(@firewall_rule_route).firewall_rule
    rule.each { |k,v| instance_variable_set("@#{k}", v) }
    @firewall_rule_route = "#{@firewall_rules_route}/#{rule.id}"
    self
  end

  def create(params)
    interface.post(@firewall_rules_route, {firewall_rule: params})
  end

  def edit(params)
    data = {
        network_interface_id: network_interface_id,
        port: params[:port].to_s,
        address: params[:address],
        command: params[:command] || 'ACCEPT',
        protocol: params[:protocol] || 'TCP'
    }
    interface.put(@firewall_rule_route, {firewall_rule: data})
    info_update
  end

  def remove
    interface.delete(@firewall_rule_route)
  end
end