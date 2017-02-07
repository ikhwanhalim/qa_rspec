class VirtualServer
  include VmOperationsWaiters, Network, SshCommands

  attr_accessor :maxmem
  attr_reader :interface, :add_to_marketplace, :admin_note, :allowed_hot_migrate, :allowed_swap, :booted, :built,
              :cores_per_socket, :cpu_shares, :cpu_sockets, :cpu_threads, :cpu_units, :cpus, :created_at,
              :customer_network_id, :deleted_at, :edge_server_type, :enable_autoscale, :enable_monitis,
              :firewall_notrack, :hostname, :hot_add_cpu, :hot_add_memory, :hypervisor_id,
              :id, :identifier, :initial_root_password,:initial_root_password_encrypted,
              :instance_type_id, :iso_id, :label, :local_remote_access_ip_address, :local_remote_access_port,
              :locked,:memory, :min_disk_size, :note, :operating_system, :operating_system_distro, :preferred_hvs,
              :recovery_mode, :remote_access_password, :service_password, :state, :storage_server_type,
              :strict_virtual_machine_id, :suspended, :template_id, :template_label, :time_zone, :updated_at,
              :user_id, :vip, :xen_id, :ip_addresses, :monthly_bandwidth_used, :total_disk_size, :price_per_hour,
              :price_per_hour_powered_off, :support_incremental_backups, :cpu_priority, :cdboot

  def initialize(interface)
    @interface = interface
  end

  def hypervisor
    interface.hypervisor
  end

  def hypervisor_type
    hypervisor.hypervisor_type
  end

  def hypervisor_group_id
    hypervisor.hypervisor_group_id
  end

  def template
    interface.template
  end

  def create(**params)
    data = interface.post('/virtual_machines', {virtual_machine: build_params.merge(params)})
    return data.errors if data.errors
    info_update(data)
    wait_for_build
    info_update
    self
  end

  def build_params
    {
      hypervisor_id: hypervisor.id,
      template_id: (template.id if defined?(template.id)),
      label: template.label,
      memory: template.min_memory_size,
      cpus: '1',
      primary_disk_size: template.min_disk_size,
      hostname: 'autotest',
      required_virtual_machine_build: '1',
      required_ip_address_assignment: '1',
      rate_limit: '0',
      required_virtual_machine_startup: '1',
      cpu_shares: ('1' if !(hypervisor_type == 'kvm' && hypervisor.distro == 'centos5')),
      swap_disk_size: ('1' if template.allowed_swap),
      licensing_type: ('mak' if template.operating_system == 'windows')
    }
  end

  def find(identifier)
    @identifier = identifier
    update_last_transaction
    info_update
    self
  end

  def locked?
    interface.get(route).virtual_machine.locked
  end

  def find_by_label(label)
    all.select { |vm| vm.label == label }
  end

  def find_by_template(image_template_id)
    all.select { |vm| vm.template_id ==  image_template_id}
  end


  def all
    interface.get('/virtual_machines').map &:virtual_machine
  end

  def update_last_transaction
    define_last_transaction_id
    interface.last_transaction_id = interface.get("/transactions", {page: 1, per_page: 10}).first['transaction']['id']
  end

  def wait_for_build(image: template, require_startup: true, rebuild: false)
    if rebuild
      disk('primary').wait_for_format
      disk('swap').wait_for_format if image.allowed_swap
    else
      disk('primary').wait_for_build
      disk('swap').wait_for_build if image.allowed_swap
    end

    if image.type == 'ImageTemplateIso'
      wait_for_build_virtual_machine
    else
      image.operating_system == 'freebsd' ? disk('swap').wait_for_provision : disk('primary').wait_for_provision
      wait_for_configure_operating_system
      wait_for_provision_freebsd if image.operating_system == 'freebsd'
      wait_for_provision_win if image.operating_system == 'windows'
    end

    wait_for_start if require_startup
    info_update
  end

  def rebuild(image: template, required_startup: 1)
    params = {
      virtual_machine: {
        template_id: image.id,
        required_startup: required_startup.to_s,
        licensing_type: build_params[:licensing_type]
      }
    }
    response = interface.post("#{route}/build", params)
    return response if api_response_code  == '422'
    wait_for_build(image: image, require_startup: !required_startup.zero?, rebuild: true)
  end

  def destroy
    interface.delete("#{route}", {destroy_all_backups: 1})
    return false if api_response_code  == '404'
    wait_for_destroy
  end

  def disk(type = 'primary', number = 1)
    if type == 'primary'
      return (disks.select { |d| d.primary }).first
    elsif type == 'swap'
      return (disks.select { |d| d.is_swap })[number-1]
    elsif type == 'additional'
      return (disks.select { |d| !d.is_swap && !d.primary })[number-1]
    end
  end

  def add_disk(**attributes)
    new_disk = Disk.new(self)
    new_disk.create({data_store_id: disk.data_store_id}.merge(attributes))
  end

  def disk_mounted?(disk)
    !!ssh_execute('mount').detect { |out| out.include? disk.identifier }
  end

  def network_interface(type = 'primary', number = 1)
    @network_interface = if type == 'primary'
      network_interfaces.detect { |d| d.primary } || @network_interface
    elsif type == 'additional'
      network_interfaces.select { |d| !d.primary }[number-1]
    end
  end

  def attach_network_interface(**params)
    nti = NetworkInterface.new(self)
    params[:network_join_id] = if params[:primary]
                                 network_interface.network_join_id
                               else
                                 available_network_join_ids.first
                               end
    nti.create(params)
  end

  def available_network_join_ids
    all_network_joins.delete_if do |j|
      j.id == network_interface.network_join_id #||
          #j.target_join_id == network_interface.ip_address.network_id
    end.map(&:id)
  end

  def all_network_joins
    all = interface.get("/settings/hypervisor_zones/#{hypervisor.hypervisor_group_id}/network_joins")
    all += interface.get("/settings/hypervisors/#{hypervisor.id}/network_joins")
    all.map(&:network_join)
  end

  def rebuild_network(**params)
    data = { is_shutdown_required: true, shutdown_type: 'graceful', required_startup: 1 }.merge(params)
    response = interface.post("#{route}/rebuild_network", data)
    return false if api_response_code  == '404'
    return response if api_response_code == '422'
    wait_for_rebuild_network
  end

  def ssh_execute(script, with_pass=false)
    cred = {
        'vm_host' => ip_address,
        'vm_pass' => initial_root_password
    }
    if interface.class.to_s == "FederationTrader" || with_pass
      interface.execute_with_pass(cred, script)
    else
      interface.tunnel_execute(cred, script)
    end
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

  def reset_root_password(root_pass: false, passphrase: false, confirmation_passphrase: false)
    if passphrase || root_pass
      params = {
          virtual_machine: {
              initial_root_password: (root_pass if root_pass),
              initial_root_password_encryption_key: (passphrase if passphrase),
              initial_root_password_encryption_key_confirmation: (confirmation_passphrase if confirmation_passphrase) }
      }
      response = interface.post("#{route}/reset_password", params)
    else
      response = interface.post("#{route}/reset_password")
    end
    return response if api_response_code == '422'
    wait_for_stop
    wait_for_reset_root_password
    wait_for_start
    info_update
  end

  def decrypt_root_password(passphrase)
    interface.get("#{route}/with_decrypted_password", {initial_root_password_encryption_key: passphrase})
  end

  def set_ssh_keys
    response = interface.post("#{route}/set_ssh_keys")
    return response if api_response_code == '422'
    wait_for_set_ssh_keys
  end

  def hot_migrate(hv_id)
    response = interface.post("#{route}/migrate", {virtual_machine: {destination: hv_id}})
    return response.errors if api_response_code == '422'
    wait_for_hot_migration
    info_update
  end

  def cold_migrate(hv_id)
    response = interface.post("#{route}/migrate", {virtual_machine: {destination: hv_id}})
    return response.errors if api_response_code == '422'
    wait_for_cold_migration
    info_update
  end

  def segregate(vm_id)
    response = interface.put("#{route}/segregation", {virtual_machine: {strict_virtual_machine_id: vm_id}})
    return response.errors if api_response_code == '422'
    info_update
  end

  def desegregate(vm_id)
    response = interface.delete("#{route}/segregation", {virtual_machine: {strict_virtual_machine_id: vm_id}})
    return response if api_response_code == '422'
    info_update
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
    result = if hypervisor_type == 'kvm'
               hypervisor.ssh_execute("virsh list | grep #{identifier}")
             elsif hypervisor_type == 'xen'
               hypervisor.ssh_execute("xm list | grep #{identifier}")
             end
    !!result.last.try(:include?, identifier)
  end

  def update_os
    Log.error('DNS resolvers has not set') if ssh_execute('ping -c1 google.com;echo $?').last.to_i != 0
    command = OnVirtualServer.update_os(operating_system_distro)
    result = ssh_execute(command)
    status = result.last.to_i
    if status != 0
      Log.error("Update has failed for #{operating_system_distro}\n#{command}\n#{result.join('\n')}")
    else
      result[-5..-1].each { |line| Log.info(line) }
    end
  end

  def ip_address
    network_interface.ip_address.address
  end

  def ip_addresses
    network_interface.ip_addresses
  end

  def update_firewall_rules
    interface.post("#{route}/update_firewall_rules")
    wait_for_update_custom_firewall_rule
  end

  def info_update(data=nil)
    data ||= interface.get(route)
    data.virtual_machine.each { |k,v| instance_variable_set("@#{k}", v) }
    interface.hypervisor ||= Hypervisor.new(interface).find_by_id(hypervisor_id)
    interface.template ||= ImageTemplate.new(interface).find_by_id(template_id)
    disks
    network_interfaces
    self
  end

  def boot_from_cd(status: 'enable')
    response = interface.post("#{route}/cd_boot/#{status}")
    api_response_code == '201' ? info_update(response) : Log.warn(interface.conn.page.body.error)
  end

  def can_be_booted_from_iso?(iso)
    (memory >= iso.min_memory_size) && (iso.virtualization.include?(hypervisor_type)) && (total_disk_size > iso.min_disk_size)
  end

  def boot_from_iso(iso_id)
    response = interface.post("#{route}/startup", {iso_id: iso_id})
    return response if api_response_code == '422'
    wait_for_start
  end

  def reboot_from_iso(iso_id)
    response = interface.post("#{route}/reboot", {iso_id: iso_id})
    return response if api_response_code == '422'
    wait_for_reboot
  end

  def api_response_code
    interface.conn.page.code
  end

  def route
    "/virtual_machines/#{identifier}"
  end

  def disks(**attributes)
    wait_until do
      all = interface.get("#{route}/disks")
      @disks = attributes[:label] ? all.select { |d| d.disk.label == attributes[:label] } : all
      @disks.any?
    end
    @disks.map! do |x|
      Disk.new(self).info_update(x.disk)
    end
  end

  def network_interfaces
    wait_until do
      @network_interfaces = interface.get("#{route}/network_interfaces")
      return [] if @network_interface && @network_interfaces.empty?
      @network_interfaces.any?
    end
    @network_interfaces.map! do |x|
      NetworkInterface.new(self).info_update(x['network_interface'])
    end
  end

  def autobackup(status = 'enable')
    interface.post("#{route}/autobackup_#{status}")
  end

  def join_recipe_to(recipe_id, event_type)
    recipe_join = { recipe_join: { recipe_id: recipe_id, event_type: event_type} }
    interface.post("#{route}/recipe_joins", recipe_join)
  end

  def create_backup
    Backup.new(self).create
  end

  def get_backups(type='')
    if type == 'normal'
      interface.get("#{route}/backups/images")
    elsif type == 'incremental'
      interface.get("#{route}/backups/files")
    else
      interface.get("#{route}/backups")
    end
  end

  def autoscale_enable
    interface.post("#{route}/autoscale_enable")
    if interface.conn.page.code == '201'
      wait_for_check_or_install_zabbix_agent
      wait_for_enable_auto_scaling
    end
  end
end


