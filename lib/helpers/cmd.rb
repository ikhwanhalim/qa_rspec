class Cmd
  class << self

    def execute(command)
      output=`#{command}`
      if $?.success?
        return output
      else
        raise(output)
        return output
      end
    end

    #it return true if host available
    #false if no
    def is_pinged(ipaddress, count=8)
      puts "Ping #{ipaddress}"
      lic=0
      begin
        output=`ping  -c #{count} #{ipaddress}`
        lic+=1
      end until ( $?.success? || lic > 5 )
      if ! $?.success?
        puts "can't get response from #{ipaddress}"
        return false
      else
        sleep 2
        return true
      end
    end

  end
end
