class BackupServer
  attr_reader :compute, :backup_ip_address,:backup_server_group_id,:capacity,:cpu_idle,:created_at,:distro,:enabled,:ip_address,
              :label,:updated_at

  def initialize(compute)
    @compute = compute
  end

  def find_first_active
    servers = compute.get('/settings/backup_servers').map &:backup_server
    server = select_active_with_max_idle(servers)
    Log.error('Backup server was not found') unless server
    info_update(server)
    self
  end

  def ssh_execute(script)
    compute.tunnel_execute({'vm_host' => ip_address}, script)
  end

  def mount_vm_primary_disk
    set_disk_data
    ssh_execute("lvchange -ay /dev/#{@dsi}/#{@di}")
    ssh_execute("mkdir /mnt/onapp-tmp-#{@di}")
    ssh_execute("kpartx -a -p X /dev/#{@dsi}/#{@di}")
    ssh_execute("mount -t #{@fs} /dev/#{@dsi}/#{@di} /mnt/onapp-tmp-#{@di}")
  end

  def umount_vm_primary_disk
    ssh_execute("umount /mnt/onapp-tmp-#{@di}")
  end

  def scan_disk
    ssh_execute('freshclam')
    log = ssh_execute("clamscan -r --bell -i /mnt/onapp-tmp-#{@di}").first
    if log && log.to_s.include?('Scanned files: 0')
      Log.error('Disk has not been mounted')
    elsif log && log.to_s.include?('Infected files: 0')
      Log.info(log)
    else
      Log.error(log)
    end
  end

  private

  def set_disk_data
    @fs = compute.vm.disk.file_system
    @dsi = compute.vm.disk.data_store_identifier
    @di = compute.vm.disk.identifier
  end

  def select_active_with_max_idle(servers)
    servers.select { |s| s.backup_server_group_id && s.enabled && s.cpu_idle}
        .max &:cpu_idle
  end

  def info_update(info)
    info.each { |k,v| instance_variable_set("@#{k}", v) }
  end
end