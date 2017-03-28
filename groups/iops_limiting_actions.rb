class IopsLimiting
  TEMPLATE_MANAGER_ID = ENV['TEMPLATE_MANAGER_ID']
  HV_ID               = ENV['HV_ID']
  HVZ_ID              = ENV['HVZ_ID']
  VIRT_TYPE           = ENV['VIRT_TYPE']

  include ApiClient, Log, SshClient, ServiceChecker

  attr_reader :settings, :template, :hypervisor, :virtual_machine, :disk, :data_store

  def precondition
    @settings = Settings.new(self)
    @virtual_machine = VirtualServer.new(self)
    @template = ImageTemplate.new(self)
    @template.find_by_manager_id(TEMPLATE_MANAGER_ID)
    @hypervisor = Hypervisor.new(self)
    HV_ID ? @hypervisor.find_by_id(HV_ID) : @hypervisor.find_by_virt(VIRT_TYPE)
    @virtual_machine.create(domain: 'autotest.qa.com')

    self
  end

  def data_store_route
    "/settings/data_stores/#{virtual_machine.disks.first.data_store_id}"
  end

  def data_store_limits
    get(data_store_route).data_store.io_limits
  end

  def set_ds_io_limits(route, read_iops, write_iops, read_throughput, write_throughput)
    put("#{route}/io_limits", { "io_limits" => {
        "read_iops" => read_iops,
        "write_iops" => write_iops,
        "read_throughput" => read_throughput,
        "write_throughput" => write_throughput } })
  end

  def disk_route(id)
    "/settings/disks/#{id}"
  end

  def disk_limits(id)
    get(disk_route(id)).disk.io_limits
  end

  def set_disk_io_limits(id, io_limits_override = true, read_iops, write_iops, read_throughput, write_throughput)
    put("#{disk_route(id)}/io_limits", { "io_limits" => {
        "io_limits_override" => io_limits_override,
        "read_iops" => read_iops,
        "write_iops" => write_iops,
        "read_throughput" => read_throughput,
        "write_throughput" => write_throughput } })
  end

  # VirtualMachine IOPS measuring

  def get_limits(vm, disk = nil)
    @db_limits_for_datastore = data_store_limits
    if disk
      @db_limits_for_disk = disk_limits(disk.id)
      if disk.label == "cold_attached"
        partition = set_partition + "c1"
        mount_path = '/mnt/onapp-disk-cold_attached'
      elsif disk.label == "hot_attached"
        partition = set_partition + "d1"
        mount_path = '/mnt/onapp-disk-hot_attached'
      else
        partition = set_partition + "a1"
        mount_path = '/root/'
      end
    else
      partition = set_partition + "a1"
      mount_path = '/root/'
    end

    read_iops = vm.ssh_execute(SshCommands::OnVirtualServer.measure_read_iops(partition))[-1].to_i.round(-2)
    write_iops = vm.ssh_execute(SshCommands::OnVirtualServer.measure_write_iops(mount_path))[-1].to_i.round(-2)
    read_throughput = vm.ssh_execute(SshCommands::OnVirtualServer.measure_read_throughput(partition))[-1].split[0].to_f.round
    write_throughput = vm.ssh_execute(SshCommands::OnVirtualServer.measure_write_throughput(mount_path))[-1].split[0].to_f.round

    @measured_disk_limits = { "read_iops" => read_iops,
                              "write_iops" => write_iops,
                              "read_throughput" => read_throughput,
                              "write_throughput" => write_throughput }
  end

  def set_partition
    return "vd" if @hypervisor.hypervisor_type == "kvm"
    "xvd"
  end

  def disk_vs_limits(vm, disk = nil)
    3.times { return true if status(vm, disk) }
    false
  end

  def status(vm, disk)
    get_limits(vm, disk)
    if disk
      @db_limits_for_disk == @measured_disk_limits
    else
      @db_limits_for_datastore == @measured_disk_limits
    end
  end

  def attached_vs_limits(vm, disk)
    3.times do
      get_limits(vm, disk)
      return true if @db_limits_for_datastore == @measured_disk_limits
      false
    end
  end

  def find_hv_for_migration
    get("/settings/hypervisors").select do |h|
      h.hypervisor.hypervisor_group_id == @hypervisor.hypervisor_group_id && h.hypervisor.id != @hypervisor.id
    end.first.hypervisor.id
  end

  def install_io_ping(vm)
    if vm.operating_system_distro == "ubuntu"
      vm.ssh_execute(SshCommands::OnVirtualServer.install_ioping_ubuntu)
    elsif operating_system_distro == "centos"
      vm.ssh_execute(SshCommands::OnVirtualServer.install_ioping_centos)
    end
  end
end
