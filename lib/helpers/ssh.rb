require 'rubygems'
require 'net/ssh'


class Ssh
  class << self

    def execute_only(host, user="root", command)
      system("ssh #{user}@#{host} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o PasswordAuthentication=no `#{command}`")
    end

    def start_with_keys(host, user = "root")
      keys = `ls ~/.ssh/*.pub`
      keys.sub!(/\.pub.*\n$/,"")
      begin
        ssh = Net::SSH.start(host, user, :keys => keys, :paranoid => false)
        return ssh
      rescue SystemCallError
        puts "Failed connect to #{host} as #{user} "
#        raise
      end
    end

    def execute(host, user, pass, command)
      begin
        Net::SSH.start(host, user, :password => pass, :paranoid => false) do |ssh|
	  lic=0
	  begin
	    sleep 2
            result = ssh.exec!(command)
            puts "Executed following command '#{command}' at #{host} as #{user} with pass: #{pass}  "
	    lic+=1
    end until ( $?==0 || lic > 5 )
          ssh.close
          return result
        end
      rescue SystemCallError
        puts "Failed to execute following command '#{command}' at #{host} as #{user} with pass: #{pass}"
        raise
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
                puts "Executed following command '#{command}' at #{host} as #{user} "
          lic+=1
        end until ( $?==0 || lic > 50 )
          ssh.close
          return result
        end
      rescue SystemCallError
        puts "Failed to execute following command '#{command}' at #{host} as #{user} with responce"
        raise
      end
    end

  end
end