class NetworkInterface
  include VmOperationsWaiters

  attr_reader :interface, :virtual_machine, :ip_addresses, :firewall_rules, :connected, :created_at, :default_firewall_rule,
              :id, :identifier, :label, :mac_address, :network_join_id, :primary, :rate_limit, :updated_at, :usage,
              :usage_last_reset_at, :usage_month_rolled_at, :virtual_machine_id

  alias network_interface_id id

  def initialize(virtual_machine)
    @interface = virtual_machine.interface
    @virtual_machine = virtual_machine
  end

  def info_update(network_interface=nil)
    network_interface ||= interface.get("#{virtual_machine.route}/network_interfaces/#{id}").network_interface
    network_interface.each { |k,v| instance_variable_set("@#{k}", v) }
    @route = "#{interfaces_route}/#{id}"
    ip_addresses
    firewall_rules unless virtual_machine.firewall_notrack
    self
  end

  def interfaces_route
    "#{virtual_machine.route}/network_interfaces"
  end

  def create(**params)
    data = {network_interface: build_params.merge(params)}
    response = interface.post("#{interfaces_route}", data)
    return response.errors if interface.conn.page.code != '201'
    info_update(response.network_interface)
    wait_for_network_interface_transaction('create')
  end

  def edit(params)
    response = interface.put("#{interfaces_route}/#{id}", {network_interface: params})
    return response if interface.conn.page.code != '204'
    wait_for_update_rate_limit if params[:rate_limit]
    info_update
  end

  def any?
    interface.get(interfaces_route).any?
  end

  def remove
    interface.delete("#{@route}")
    return if interface.conn.page.code != '204'
    wait_for_network_interface_transaction('remove')
  end

  def wait_for_network_interface_transaction(action)
    if hypervisor_type == 'kvm' && hypervisor_distro == 'centos6' || hypervisor_type == 'kvm' && hypervisor_distro == 'centos7'
      if template_kvm_virtio?
        action == 'create' ? wait_for_attach_network_interface : wait_for_detach_network_interface
      else
        virtual_machine.wait_for_reboot
      end
    elsif hypervisor_type == 'kvm' && hypervisor_distro == 'centos5'
      virtual_machine.wait_for_reboot
    else
      action == 'create' ? wait_for_attach_network_interface : wait_for_detach_network_interface
    end
  end

  def hypervisor_type
    interface.hypervisor.hypervisor_type
  end

  def hypervisor_distro
    interface.hypervisor.distro
  end

  def template_kvm_virtio?
    interface.template.virtualization.include? 'kvm_virtio'
  end

  def build_params
    {
      label: 'eth2',
      rate_limit: 0
    }
  end

  def ip_addresses_route
    "#{virtual_machine.route}/ip_addresses"
  end

  def firewall_rules_route
    "#{virtual_machine.route}/firewall_rules"
  end

  def ip_addresses
    interface.get(ip_addresses_route).map do |ip_join|
      if ip_join.ip_address_join.network_interface_id.to_s == id.to_s
        IpAddress.new(self).info_update(ip_join.ip_address_join)
       end
      end
  end

  def firewall_rules
    interface.get(firewall_rules_route).map do |rule|
      if rule.firewall_rule.network_interface_id.to_s == id.to_s
        FirewallRule.new(self).info_update(rule.firewall_rule)
      end
    end
  end

  def ip_address(order_number = 1)
    if ip_addresses.any?
      ip_addresses[order_number-1]
    else
      Log.info("There is no ip addresses associated with #{@route} network interface")
      nil
    end
  end

  def allocate_new_ip(ip_address_id: nil, used_ip: 0, address: nil)
    ip = IpAddress.new(self)
    response = ip.attach(id, ip_address_id, used_ip, address)
    return response if interface.conn.page.code != '201'
    wait_for_update_firewall
    ip
  end

  def remove_ip(number = 0, rebuild_network = false)
    ip_address(number).detach(rebuild_network)
    return if interface.conn.page.code != '204'
    wait_for_update_firewall
    wait_for_rebuild_network if rebuild_network
    ip_addresses
  end

  def set_default_firewall_rule(command = 'ACCEPT')
    data = {:network_interfaces => { id => {:default_firewall_rule => command}}}
    interface.put("#{firewall_rules_route}/update_defaults", data)
    firewall_rules
  end

  def add_custom_firewall_rule(**params)
    data = {
      network_interface_id: id,
      port: params[:port].to_s,
      address: params[:address],
      command: params[:command] || 'ACCEPT',
      protocol: params[:protocol] || 'TCP'
    }
    FirewallRule.new(self).create(data)
    return if interface.conn.page.code != '201'
    firewall_rules
  end

  def amount
    command = SshCommands::OnVirtualServer.network_interfaces_amount
    virtual_machine.ssh_execute(command).last.to_i
  end

  def port_speed
    command = SshCommands::OnHypervisor.nic_rate_limit(identifier)
    interface.hypervisor.ssh_execute(command).last.to_i
  end

  def reset_firewall_rules
    firewall_rules.map &:remove
    set_default_firewall_rule
  end
end