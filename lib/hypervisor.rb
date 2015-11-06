class Hypervisor
  attr_reader :interface, :allow_unsafe_assigned_interrupts, :backup, :backup_ip_address, :blocked, :built, :called_in_atnull,
              :cloud_boot_os, :connection_options, :cpu_cores, :cpu_idle, :cpu_mhz, :cpu_units, :cpus, :created_at,
              :custom_config, :disable_failover, :disks_per_storage_controller, :distro, :dom0_memory_size, :enabled,
              :failure_count, :format_disks, :free_mem, :host, :host_id, :hypervisor_group_id, :hypervisor_type, :id,
              :infiniband_identifier, :ip_address, :label, :list_of_logical_volumes, :list_of_volume_groups,
              :list_of_zombie_domains, :locked, :mac, :machine, :mem_info, :mtu, :online, :ovs, :passthrough_disks,
              :power_cycle_command, :rebooting, :release, :server_type, :spare, :storage_controller_memory_size,
              :threads_per_core, :total_mem, :total_zombie_mem, :updated_at, :uptime, :total_cpus, :free_memory,
              :used_cpu_resources, :total_memory, :free_disk_space, :memory_allocated_by_running_vms,
              :total_memory_allocated_by_vms, :storage

  def initialize(interface)
    @interface = interface
  end

  def find_by_id(id)
    data = interface.get("/hypervisors/#{id}").hypervisor
    info_update(data)
    self
  end

  def find_by_virt(virt, hvz_id = nil)
    max_free = 0
    hv = nil
    virtualization = select_virtualization(virt)
    distro = select_distro(virt)
    interface.get("/hypervisors").map(&:hypervisor).each do |h|
      if max_free < h.free_memory && h.distro == distro && h.hypervisor_type == virtualization &&
          h.enabled && h.server_type == 'virtual' && h.online
        hv = hvz_id ? (h if hvz_id == h.hypervisor_group_id) : h
        max_free = h.free_memory
      end
    end
    Log.info("Hypervisor with id #{hv.id} has been selected")
    hv ? info_update(hv) : Log.error('Hypervisor was not found')
  end

  def ssh_execute(script)
    interface.tunnel_execute({'vm_host' => ip_address}, script)
  end

  private

  def select_virtualization(virt)
    if virt == 'xen3' || virt == 'xen4'
      'xen'
    elsif virt == 'kvm5' || virt == 'kvm6'
      'kvm'
    end
  end

  def select_distro(virt)
    if virt == 'xen3' || virt == 'kvm5'
      'centos5'
    elsif virt == 'xen4' || virt == 'kvm6'
      'centos6'
    end
  end

  def info_update(info)
    info.each { |k,v| instance_variable_set("@#{k}", v) }
  end
end