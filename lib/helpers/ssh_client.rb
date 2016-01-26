module SshClient
  HOST_KEY_VERIFICATION = '-o StrictHostKeyChecking=no'
  #Example for cred - {'vm_user'=>'name', 'vm_host'=>'ip', 'cp_hostname'=>'name', 'cp_ip'=>'ip'}
  def tunnel_execute(cred={}, command)
    Log.error("HV ip should not be nil") unless cred['vm_host']
    cmd = "echo \"#{command}\" | ssh -T #{HOST_KEY_VERIFICATION} onapp@#{ip} ssh -T #{HOST_KEY_VERIFICATION} root@#{cred['vm_host']}"
    Log.info(cmd)
    %x[ #{cmd} 2>&1 ].split /[\r,\n]/
  end

  #Example for cred - {'vm_user'=>'name', 'vm_host'=>'ip', 'vm_pass'=>'pass'}
  def execute_with_pass(cred={}, command)
    Log.info("Execute #{command}. Credentials #{cred['vm_host']}/#{cred['vm_pass']}")
    Net::SSH.start(cred['vm_host'], cred['vm_user'] || 'root', :password => cred['vm_pass'], :paranoid => false) do |ssh|
      ssh.exec!(command).to_s.split("\n")
    end
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
end