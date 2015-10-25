require 'virtual_machine/vm_operations_waiter'
require 'disk'
require 'network_interface'

class VirtualServer
  include VmOperationsWaiters

  attr_accessor :maxmem
  attr_reader :compute, :add_to_marketplace, :admin_note, :allowed_hot_migrate, :allowed_swap, :booted, :built,
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

  def initialize(compute)
    @compute = compute
  end

  def create
    hash ={'virtual_machine' => {
        'hypervisor_id' => compute.hypervisor.id,
        'template_id' => compute.template.id,
        'label' => compute.template.label,
        'memory' => compute.template.min_memory_size,
        'cpus' => '1',
        'primary_disk_size' => compute.template.min_disk_size,
        'hostname' => 'auto.compute',
        'required_virtual_machine_build' => '1',
        'required_ip_address_assignment' => '1',
        'rate_limit' => '0'
    }
    }
    hash['virtual_machine']['cpu_shares'] = '1' if !(compute.hypervisor.hypervisor_type == 'kvm' && compute.hypervisor.distro == 'centos5')
    hash['virtual_machine']['swap_disk_size'] = '1' if compute.template.allowed_swap
    result = compute.post('/virtual_machines', hash)
    compute.check_responce_code('201')
    info_update(result['virtual_machine'])
    self
  end

  def wait_for_build(require_startup = true)
    disk('primary').wait_for_build
    disk('swap').wait_for_build if compute.template.allowed_swap
    disk('swap').wait_for_provision if compute.template.operating_system == 'freebsd'
    disk('primary').wait_for_provision if compute.template.operating_system != 'freebsd'
    wait_for_configure_operating_system
    wait_for_provision_freebsd if compute.template.operating_system == 'freebsd'
    wait_for_provision_win if compute.template.operating_system == 'windows'
    wait_for_start if require_startup
    info_update
  end

  def destroy
    compute.delete("#{@route}")
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

  def ssh_execute(script, ip)
    ip ||= network_interface.ip_address.address
    cred = {'vm_host' => ip, 'vm_pass' => initial_root_password}
    compute.execute_with_pass(cred, script)
  end

  def stop
    compute.post("#{@route}/stop")
    wait_for_stop
  end

  def shut_down
    compute.post("#{@route}/shutdown")
  end

  def start_up
    compute.post("#{@route}/startup")
  end

  def reboot
    compute.post("#{@route}/reboot")
  end


  def info_update(info = false)
    info = compute.get(@route)if !info
    info.each { |k,v| instance_variable_set("@#{k}", v) }
    @route = "/virtual_machines/#{self.identifier}"
    disk_info_update
    network_interface_info_update
    self
  end

  private

  def disk_info_update
    @disks = compute.get("#{@route}/disks")
    @disks.map! do |x|
      Disk.new(compute).info_update(x['disk'])
    end
  end

  def network_interface_info_update
    @network_interfaces = compute.get("#{@route}/network_interfaces")
    @network_interfaces.map! do |x|
      NetworkInterface.new(compute, @route).info_update(x['network_interface'])
    end
  end
end


