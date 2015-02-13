require 'json'
require 'net/ssh'

module OnappSSH


  #Example for cred - {'vm_user'=>'name', 'vm_host'=>'ip', 'cp_hostname'=>'name', 'cp_ip'=>'ip'}
  def tunnel_execute(cred={}, command)
    cred['cp_ip'] ||= @ip
    cred['cp_hostname'] ||= 'onapp'
    Log.error("HV ip should not be nil") unless cred['vm_host']
    cred['vm_user'] ||= 'root'
    cmd = "echo '%s' | ssh -t %s@%s ssh %s@%s" % [command,
                                                      cred['cp_hostname'], cred['cp_ip'],
                                                      cred['vm_user'], cred['vm_host'],]
    %x[ #{cmd} ].split("\r\n")
  end

  #Example for cred - {'vm_user'=>'name', 'vm_host'=>'ip', 'vm_pass'=>'pass'}
  def execute_with_pass(cred={}, command)
    require 'pry';binding.pry
    cred['vm_host'] ||= @vm_ip
    cred['vm_pass'] ||= @virtual_machine['initial_root_password']
    ssh = Net::SSH.start(cred['vm_host'], cred['vm_user'] || 'root', :password => cred['vm_pass'], :paranoid => false)
    ssh.exec!(command).to_s.split("\n")
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

  def memory
    if system == 'linux'
      execute_with_pass("free -m |awk '{print $2}'| sed -n 2p")
    elsif system == 'freebsd'
      execute_with_pass("dmesg | awk '/real memory/ {print $4/1024/1024}'")
    end.first
  end

  def cpu
    if system == 'linux'
      execute_with_pass("cat /proc/cpuinfo |grep processor |tail -1 |awk '{print $3+1}'")
    elsif system == 'freebsd'
      execute_with_pass("dmesg | grep -oE 'cpu[0-9]*' | awk 'END{printf \"%.0f\n\", (NR+0.1)/2}'")
    end.first
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