class VirtualServer
  include VmOperationsWaiters, Network, SshCommands

  attr_accessor :maxmem
  attr_reader :interface, :add_to_marketplace, :admin_note, :allowed_hot_migrate, :allowed_swap, :booted, :built,
              :cores_per_socket, :cpu_shares, :cpu_sockets, :cpu_threads, :cpu_units, :cpus, :created_at,
              :customer_network_id, :deleted_at, :edge_server_type, :enable_autoscale, :enable_monitis,
              :firewall_notrack, :hostname, :hot_add_cpu, :hot_add_memory, :hypervisor_id,
              :id, :identifier, :vwu1gypsg8umxm,:initial_root_password,:initial_root_password_encrypted,
              :instance_type_id, :iso_id, :label,:local_remote_access_ip_address,:local_remote_access_port,
              :locked,:memory, :min_disk_size, :note,:operating_system,:operating_system_distro,:preferred_hvs,
              :recovery_mode, :remote_access_password, :service_password, :state, :storage_server_type,
              :strict_virtual_machine_id, :suspended, :template_id, :template_label, :time_zone,:updated_at,
              :user_id, :vip, :xen_id, :ip_addresses, :monthly_bandwidth_used, :total_disk_size, :price_per_hour,
              :price_per_hour_powered_off, :support_incremental_backups, :cpu_priority

  def initialize(interface)
    @interface = interface
  end

  def create
    hash ={'virtual_machine' => {
        'hypervisor_id' => interface.hypervisor.id,
        'template_id' => interface.template.id,
        'label' => interface.template.label,
        'memory' => interface.template.min_memory_size,
        'cpus' => '1',
        'primary_disk_size' => interface.template.min_disk_size,
        'hostname' => 'auto.interface',
        'required_virtual_machine_build' => '1',
        'required_ip_address_assignment' => '1',
        'rate_limit' => '0',
        'required_virtual_machine_startup' => '1'
    }
    }
    hash['virtual_machine']['cpu_shares'] = '1' if !(interface.hypervisor.hypervisor_type == 'kvm' && interface.hypervisor.distro == 'centos5')
    hash['virtual_machine']['swap_disk_size'] = '1' if interface.template.allowed_swap
    data = interface.post('/virtual_machines', hash)
    return data.errors if data.errors
    info_update(data)
    wait_for_build
    info_update
    self
  end

  def find(identifier)
    @identifier = identifier
    info_update
    interface.hypervisor ||= Hypervisor.new(interface).find_by_id(hypervisor_id)
    self
  end

  def wait_for_build(require_startup = true)
    disk('primary').wait_for_build
    disk('swap').wait_for_build if interface.template.allowed_swap
    disk('swap').wait_for_provision if interface.template.operating_system == 'freebsd'
    disk('primary').wait_for_provision if interface.template.operating_system != 'freebsd'
    wait_for_configure_operating_system
    wait_for_provision_freebsd if interface.template.operating_system == 'freebsd'
    wait_for_provision_win if interface.template.operating_system == 'windows'
    wait_for_start if require_startup
    info_update
  end

  def destroy
    interface.delete("#{route}")
    wait_for_destroy
  end

  def disk(type = 'primary', number = 1)
    if type == 'primary'
      return (@disks.select { |d| d.primary }).first
    elsif type == 'swap'
      return (@disks.select { |d| d.is_swap })[number-1]
    elsif type == 'additional'
      return (@disks.select { |d| !d.is_swap && !d.primary })[number-1]
    end
  end

  def network_interface(type = 'primary', number = 1)
    if type == 'primary'
      return (@network_interfaces.select { |d| d.primary }).first
    elsif type == 'additional'
      return (@network_interfaces.select { |d| !d.primary })[number-1]
    end
  end

  def ssh_execute(script)
    cred = {
        'vm_host' => ip_address,
        'vm_pass' => initial_root_password
    }
    interface.execute_with_pass(cred, script)
  end

  def stop
    interface.post("#{route}/stop")
    wait_for_stop
  end

  def shut_down
    interface.post("#{route}/shutdown")
    wait_for_stop
  end

  def start_up
    interface.post("#{route}/startup")
    wait_for_start
  end

  def reboot
    interface.post("#{route}/reboot")
    wait_for_reboot
  end

  def update_os
    command = case operating_system_distro
                when 'rhel' then RHEL.update_os
                when 'ubuntu' then UBUNTU.update_os
              end
    result = ssh_execute(command)
    status = result.last.to_i
    Log.error("Update has failed for #{operating_system_distro}\n#{command}\n#{result.join('\n')}") if status != 0
  end

  def ip_address
    network_interface.ip_address.address
  end

  def info_update(data=nil)
    data ||= interface.get(route)
    data.virtual_machine.each { |k,v| instance_variable_set("@#{k}", v) }
    disk_info_update
    network_interface_info_update
    self
  end

  def reboot_from_iso(iso_id)
    params = {}
    params[:iso_id] = iso_id
    interface.post("#{route}/reboot", params)
    return interface.conn.page.body.error if api_response_code != '201'
  end

  def api_response_code
    interface.conn.page.code
  end

  private

  def route
    @route ||= "/virtual_machines/#{identifier}"
  end

  def disk_info_update
    @disks = interface.get("#{route}/disks")
    @disks.map! do |x|
      Disk.new(interface).info_update(x['disk'])
    end
  end

  def network_interface_info_update
    @network_interfaces = interface.get("#{route}/network_interfaces")
    @network_interfaces.map! do |x|
      NetworkInterface.new(interface, route).info_update(x['network_interface'])
    end
  end
end


