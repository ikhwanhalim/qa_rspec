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
              :total_memory_allocated_by_vms, :storage, :id

  def initialize(interface)
    @interface = interface
  end

  def create(**params)
    response = interface.post('/settings/hypervisors', {hypervisor: build_data.merge(params) })
    info_update(response['hypervisor'])
  end

  def build_data
    {
      label: "Hypervisor_#{SecureRandom.hex(4)}",
      hypervisor_type: 'xen',
      ip_address: Faker::Internet.ip_v4_address,
      cpu_units: '1000',
      enabled: true,
      collect_stats: true,
      disable_failover:false
    }
  end

  def remove(hypervisor_id)
    interface.delete("/settings/hypervisors/#{hypervisor_id}")
  end

  def available_hypervisor_for_migration
    find_by_virt(ENV['VIRT_TYPE'], hypervisor_group_id, exclude_current: true)
  end

  def find_by_id(id)
    data = interface.get("/settings/hypervisors/#{id}").hypervisor
    info_update(data)
    self
  end

  def find_by_virt(virt = nil, hvz_id = nil, exclude_current: false)
    max_free = 0
    hv = nil
    virtualization = select_virtualization(virt) if virt
    distro = select_distro(virt) if virt
    cb_ids = cloud_boot_ids
    interface.get("/settings/hypervisors").map(&:hypervisor).each do |h|
      if max_free < h.free_memory && online_suitable_hv?(h)
        next if cb_ids && cb_ids.include?(h.id) && !ENV['CLOUDBOOT']
        next if exclude_current && h.id == id
        next if virt && !(h.distro == distro && h.hypervisor_type == virtualization)
        next if hvz_id && hvz_id != h.hypervisor_group_id
        hv = h
        max_free = h.free_memory
      end
    end

    if exclude_current
      if hv
        info_update(hv)
        Log.info("Hypervisor with id #{hv.id} has been selected for migration")
        return self
      else
        return hv
      end
    else
        hv ? info_update(hv) : Log.error('Hypervisor was not found')
        Log.info("Hypervisor with id #{hv.id} has been selected")
        self
    end
  end

  def online_suitable_hv?(hypervisor)
      hypervisor.enabled && hypervisor.server_type == 'virtual' && hypervisor.online && hypervisor.label !~ /fake/i &&
          hypervisor.hypervisor_group_id != nil && hypervisor.hypervisor_type != 'vcenter'  &&
          (!ENV['TEMPLATE_MANAGER_ID'] || interface.template.virtualization.include?(hypervisor.hypervisor_type) )
  end

  def cloud_boot_ids
    if interface.settings.cloud_boot_enabled
      interface.get('/cloud_boot_ip_addresses').map { |ip| ip.ip_address.hypervisor_id }
    else
      false
    end
  end

  def find_cdn_location_group
    @cdn_location_groups = []
    interface.get('/settings/location_groups').each {|x| @cdn_location_groups << x.location_group.id if x.location_group.cdn_enabled? }
  end

  def find_cdn_hvz
    find_cdn_location_group
    @cdn_hvz = []
    interface.get("/settings/location_groups/#{@cdn_location_groups.sample(1).join}/hypervisor_groups").each {|x| @cdn_hvz << x.hypervisor_group.id if x.hypervisor_group.server_type == 'virtual' }
  end

  def find_cdn_supported(hvz_id = nil, hv_id = nil)
    hv = nil
    max_free = 0
    if hvz_id
      #TODO Andrii refactor
      interface.get("/settings/hypervisor_zones/#{hvz_id}/hypervisors").map(&:hypervisor).each do |h|
        if max_free < h.free_memory && h.enabled && h.server_type == 'virtual' && h.online && h.label !~ /fake/i
          hv = hv_id ? (h if hv_id == h.hypervisor_group_id) : h
          max_free = h.free_memory
        end
      end
    else
      find_cdn_hvz
      size_cdn_hvz = @cdn_hvz.count - 1
      interface.get("/settings/hypervisor_zones/#{@cdn_hvz[rand(0..size_cdn_hvz)]}/hypervisors").map(&:hypervisor).each do |h|
        if max_free < h.free_memory && h.enabled && h.server_type == 'virtual' && h.online && h.label !~ /fake/i
          hv = hv_id ? (h if hv_id == h.hypervisor_group_id) : h
          max_free = h.free_memory
        end
      end
    end

    hv ? info_update(hv) : Log.error('Hypervisor was not found')
    Log.info("Hypervisor with id #{hv.id} has been selected")
    self
  end

  def ssh_execute(script)
    interface.tunnel_execute({'vm_host' => ip_address}, script)
  end

  def remount_data
    command = SshCommands::OnHypervisor.force_remount_data(interface.ip)
    ssh_execute command
  end

  def is_data_mounted?
    command = SshCommands::OnHypervisor.data_mounted
    ssh_execute(command).join.include?(':/data')
  end

  def find_exist(path, file_name)
    command = SshCommands::OnHypervisor.find_file(path, file_name)
    ssh_execute(command).last.try(:include?, file_name)
  end

  private

  def select_virtualization(virt)
    if virt == 'xen3' || virt == 'xen4' || virt == 'xen7'
      'xen'
    elsif virt == 'kvm5' || virt == 'kvm6' || virt == 'kvm7'
      'kvm'
    end
  end

  def select_distro(virt)
    if virt == 'xen3' || virt == 'kvm5'
      'centos5'
    elsif virt == 'xen4' || virt == 'kvm6'
      'centos6'
    elsif virt == 'kvm7' || virt == 'xen7'
      'centos7'
    end
  end

  def info_update(info)
    info.each { |k,v| instance_variable_set("@#{k}", v) }
  end
end