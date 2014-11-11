module OnappSSH

  def cp_execute(cred={}, command)
    cred['cp_ip'] ||= @ip
    cred['cp_hostname'] ||= 'onapp'
    cmd = "ssh -At %s@%s %s" % [cred['cp_hostname'], cred['cp_ip'], command]
    %x[ #{cmd} ].split "\r\n"
  end

  def hv_execute(cred={}, command)
    cred['cp_ip'] ||= @ip
    cred['cp_hostname'] ||= 'onapp'
    raise "HV ip should not be nil" unless cred['hv_ip']
    cred['hv_hostname'] ||= 'root'
    cmd = "ssh -At %s@%s ssh -At %s@%s %s" % [cred['cp_hostname'], cred['cp_ip'],
                                                 cred['hv_hostname'], cred['hv_ip'],
                                                 command]
    %x[ #{cmd} ].split "\r\n"
  end
end