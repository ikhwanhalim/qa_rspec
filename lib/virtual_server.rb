class VirtualServer
  include VmOperationsWaiters, Network, SshCommands

  attr_accessor :maxmem
  attr_reader :interface, :add_to_marketplace, :admin_note, :allowed_hot_migrate, :allowed_swap, :booted, :built,
              :cores_per_socket, :cpu_shares, :cpu_sockets, :cpu_threads, :cpu_units, :cpus, :created_at,
              :customer_network_id, :deleted_at, :edge_server_type, :enable_autoscale, :enable_monitis,
              :firewall_notrack, :hostname, :hot_add_cpu, :hot_add_memory, :hypervisor_id,
              :id, :identifier,:initial_root_password,:initial_root_password_encrypted,
              :instance_type_id, :iso_id, :label,:local_remote_access_ip_address,:local_remote_access_port,
              :locked,:memory, :min_disk_size, :note,:operating_system,:operating_system_distro,:preferred_hvs,
              :recovery_mode, :remote_access_password, :service_password, :state, :storage_server_type,
              :strict_virtual_machine_id, :suspended, :template_id, :template_label, :time_zone,:updated_at,
              :user_id, :vip, :xen_id, :ip_addresses, :monthly_bandwidth_used, :total_disk_size, :price_per_hour,
              :price_per_hour_powered_off, :support_incremental_backups, :cpu_priority

  def initialize(interface)
    @interface = interface
  end

  def hypervisor
    interface.hypervisor
  end

  def template
    interface.template
  end

  def create
    hash = {
      'virtual_machine' => {
        'hypervisor_id' => hypervisor.id,
        'template_id' => template.id,
        'label' => template.label,
        'memory' => template.min_memory_size,
        'cpus' => '1',
        'primary_disk_size' => template.min_disk_size,
        'hostname' => 'auto.interface',
        'required_virtual_machine_build' => '1',
        'required_ip_address_assignment' => '1',
        'rate_limit' => '0',
        'required_virtual_machine_startup' => '1'
      }
    }
    hash['virtual_machine']['cpu_shares'] = '1' if !(hypervisor.hypervisor_type == 'kvm' && hypervisor.distro == 'centos5')
    hash['virtual_machine']['swap_disk_size'] = '1' if template.allowed_swap
    data = interface.post('/virtual_machines', hash)
    return data.errors if data.errors
    info_update(data)
    wait_for_build
    info_update
    self
  end

  def find(identifier)
    @identifier = identifier
    update_last_transaction
    info_update
    self
  end

  def find_by_label(label)
    interface.get('/virtual_machines').select { |vm| vm.label == label }
  end

  def all
    interface.get('/virtual_machines')
  end

  def update_last_transaction
    @last_transaction_id = interface.get("#{route}/transactions", {page: 1, per_page: 10}).first['transaction']['id']
  end

  def wait_for_build(require_startup = true)
    disk('primary').wait_for_build
    disk('swap').wait_for_build if template.allowed_swap
    disk('swap').wait_for_provision if template.operating_system == 'freebsd'
    disk('primary').wait_for_provision if template.operating_system != 'freebsd'
    wait_for_configure_operating_system
    wait_for_provision_freebsd if template.operating_system == 'freebsd'
    wait_for_provision_win if template.operating_system == 'windows'
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

  def suspend
    interface.post("#{route}/suspend")
    wait_for_stop
  end

  def unsuspend
    interface.post("#{route}/suspend")
  end

  def start_up
    response = interface.post("#{route}/startup")
    return response if api_response_code == '422'
    wait_for_start
  end

  def reboot(recovery: false)
    if recovery
      interface.post("#{route}/reboot",'','?mode=recovery')
    else
      interface.post("#{route}/reboot")
    end
    wait_for_reboot
  end

  #Keyword arguments - label, cpus, cpu_shares, memory
  def edit(**kwargs)
    interface.put(route, {virtual_machine: kwargs})
    diff_cpu = kwargs[:cpus] && kwargs[:cpus] != cpus
    diff_mem = kwargs[:memory] && kwargs[:memory] != memory
    def_cpu_shares = kwargs[:cpu_shares] && kwargs[:cpu_shares] != cpu_shares
    if  diff_cpu || diff_mem || def_cpu_shares
      template.allow_resize_without_reboot ? wait_for_resize_without_reboot : wait_for_resize
    end
    info_update
  end

  def exist_on_hv?
    result = if hypervisor.hypervisor_type == 'kvm'
               hypervisor.ssh_execute("virsh list | grep #{identifier}")
             elsif hypervisor.hypervisor_type == 'xen'
               hypervisor.ssh_execute("xm list | grep #{identifier}")
             end
    Log.info(result)
    result.last.include?(identifier)
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
    interface.hypervisor ||= Hypervisor.new(interface).find_by_id(hypervisor_id)
    interface.template ||= ImageTemplate.new(interface).find_by_id(template_id)
    disk_info_update
    network_interface_info_update
    self
  end

  def can_be_booted_from_iso?
    memory >= interface.iso.min_memory_size
  end

  def reboot_from_iso(iso_id)
    params = {}
    params[:iso_id] = iso_id
    interface.post("#{route}/reboot", params)
    return Log.warn(interface.conn.page.body.error) if api_response_code != '201'
    wait_for_reboot
  end

  def api_response_code
    interface.conn.page.code
  end

  private

  def route
    @route ||= "/virtual_machines/#{identifier}"
  end

  def disk_info_update
    wait_until do
      @disks = interface.get("#{route}/disks")
      @disks.any?
    end
    @disks.map! do |x|
      Disk.new(interface).info_update(x['disk'])
    end
  end

  def network_interface_info_update
    wait_until do
      @network_interfaces = interface.get("#{route}/network_interfaces")
      @network_interfaces.any?
    end
    @network_interfaces.map! do |x|
      NetworkInterface.new(interface, route).info_update(x['network_interface'])
    end
  end
end


