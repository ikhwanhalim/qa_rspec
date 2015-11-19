module SshClient
  #Example for cred - {'vm_user'=>'name', 'vm_host'=>'ip', 'cp_hostname'=>'name', 'cp_ip'=>'ip'}
  def tunnel_execute(cred={}, command)
    Log.error("HV ip should not be nil") unless cred['vm_host']
    credentials = [
        command,
        cred['cp_hostname'] || 'onapp',
        cred['cp_ip'],
        cred['vm_user'] || 'root',
        cred['vm_host']
    ]
    cmd = "echo \"%s\" | ssh -t %s@%s ssh %s@%s" % credentials
    Log.info(cmd)
    %x[ #{cmd} ].split("\r\n")
  end

  #Example for cred - {'vm_user'=>'name', 'vm_host'=>'ip', 'vm_pass'=>'pass'}
  def execute_with_pass(cred={}, command)
    Log.info("#Execute #{command}. Credentials #{cred['vm_host']}/#{cred['vm_pass']}")
    ssh = Net::SSH.start(cred['vm_host'], cred['vm_user'] || 'root', :password => cred['vm_pass'], :paranoid => false)
    ssh.exec!(command).to_s.split("\n")
  end

  def execute_with_keys(host, user, command)
    keys = `ls ~/.ssh/*.pub`
    keys.sub!(/\.pub.*\n$/,"")
    begin
      Net::SSH.start(host, user, :keys => keys, :paranoid => false) do |ssh|
        lic=0
        begin
          sleep 2
          result = ssh.exec!(command)
          Log.info("Executed following command '#{command}' at #{host} as #{user} ")
          lic+=1
        end until ( $?==0 || lic > 50 )
        ssh.close
        return result
      end
    rescue SystemCallError
      Log.error("Failed to execute following command '#{command}' at #{host} as #{user} " +$!)
      raise
    end
  end

  def primary_disk
    execute_with_pass("df -hm | awk '{if($6==\"/\") print $2}'").first
  end

  def mounted_disks
    disks = execute_with_pass("df -hm | awk -v dd=':' '/mnt/ {print $6dd$2}'")
    disks.map! do |disk|
      {mount_point: disk.split(':')[0], size: disk.split(':')[1]}
    end
  end

  def swap
    if system == 'linux'
      execute_with_pass("free -m | grep wap: | awk {'print $2-G-B-H'}")
    elsif system == 'freebsd'
      execute_with_pass("swapinfo -hm | awk '/dev/ {print $2}'")
    end.first
  end

  def memory_on_vm
    if system == 'linux'
      execute_with_pass("free -m |awk '{print $2}'| sed -n 2p")
    elsif system == 'freebsd'
      execute_with_pass("dmesg | awk '/real memory/ {print $4/1024/1024}'")
    end.first
  end

  def cpus_on_vm
    if system == 'linux'
      execute_with_pass("cat /proc/cpuinfo |grep processor |tail -1 |awk '{print $3+1}'")
    elsif system == 'freebsd'
      execute_with_pass("dmesg | grep -oE 'cpu[0-9]*' | awk 'END{printf \"%.0f\n\", (NR+0.1)/2}'")
    end.first
  end

  def cpu_shares_on_hv
    cred = { 'vm_host' => "#{@hypervisor['ip_address']}" }
    if @hypervisor['hypervisor_type'] == 'kvm'
      result = tunnel_execute(cred, "virsh schedinfo #{@virtual_machine['identifier']} | grep cpu_shares").first.scan(/\d+/).first
    elsif @hypervisor['hypervisor_type'] == 'xen'
      result = tunnel_execute(cred, "xm sched-credit | grep #{@virtual_machine['identifier']} || echo 'false'").first.split(' ')[2].to_i/@virtual_machine['cpus'].to_i
    end
    return result
  end

  def check_hostname
    execute_with_pass('hostname')
  end

  def primary_network_interface
    execute_with_pass("ip route get 8.8.8.8 | awk '{if($1==\"8.8.8.8\") print $5}'").first
  end

  def primary_network_ip
    execute_with_pass("ip route get 8.8.8.8 | awk '{if($1==\"8.8.8.8\") print $7}'").first
  end

  private

  def system
    @virtual_machine['operating_system']
  end
end