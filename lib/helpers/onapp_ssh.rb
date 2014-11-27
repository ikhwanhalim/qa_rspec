require 'json'
require 'net/ssh'

module OnappSSH

  #Example for cred - {'vm_user'=>'name', 'vm_host'=>'ip', 'vm_pass'=>'pass'}
  #Command can be as string  "hostname;ifconfig" or file File.open("path/to/file")
  def vm_execute(cred={}, command)
    raise "VM ip should not be nil" unless cred['vm_host']
    cred['vm_user'] ||= 'root'
    if command.kind_of? File
      cmd = "cat %s | ssh %s@%s" % [command.path, cred['vm_user'], cred['vm_host']]
      JSON.parse(%x[ #{cmd} ])
    else
      cmd = "echo '%s' | ssh %s@%s" % [command, cred['vm_user'], cred['vm_host']]
      %x[ #{cmd} ].split("\r\n")
    end
  end

  #Example for cred - {'vm_user'=>'name', 'vm_host'=>'ip', 'cp_hostname'=>'name', 'cp_ip'=>'ip'}
  def tunnel_execute(cred={}, command)
    cred['cp_ip'] ||= @ip
    cred['cp_hostname'] ||= 'onapp'
    raise "HV ip should not be nil" unless cred['vm_host']
    cred['vm_user'] ||= 'root'
    if command.kind_of? File
      cmd = "cat %s | ssh -t %s@%s ssh %s@%s" % [command.path,
                                                cred['cp_hostname'], cred['cp_ip'],
                                                cred['vm_user'], cred['vm_host'],]
      JSON.parse(%x[ #{cmd} ])
    else
      cmd = "echo '%s' | ssh -t %s@%s ssh %s@%s" % [command,
                                                      cred['cp_hostname'], cred['cp_ip'],
                                                      cred['vm_user'], cred['vm_host'],]
      %x[ #{cmd} ].split("\r\n")
    end
  end

  #Example for cred - {'vm_user'=>'name', 'vm_host'=>'ip', 'vm_pass'=>'pass'}
  #Command can be as string  "hostname;ifconfig" or file File.open("path/to/file")
  def execute_with_pass(cred={}, command)
    ssh = Net::SSH.start(cred['vm_host'], cred['vm_user'], :password => cred['vm_pass'], :paranoid => false)
    result = command.kind_of?(File) ? ssh.exec!(command.read) : ssh.exec!(command).split("\n")
  end
end