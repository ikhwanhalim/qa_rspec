module Network
  include Waiter

  def ssh_opened?(port = 22)
    Log.info("Connect to: #{ip_address}:#{port}")
    wait_until(300) do
      begin
        TCPSocket.new(ip_address, port).close
        return true
      rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
        false
      end
    end
  end

  def ssh_closed?(port = 22)
    Log.info("Connect to: #{ip_address}:#{port}")
    wait_until(300) do
      begin
        TCPSocket.new(ip_address, port).close
        false
      rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
        return true
      end
    end
  end

  def pinged?
    Log.info("Ping IP address: #{ip_address}")
    wait_until(300) do
      Net::Ping::External.new(ip_address).ping ? true : false
    end
  end

  def not_pinged?
    Log.info("Ping IP address: #{ip_address}")
    wait_until(300) do
      Net::Ping::External.new(ip_address).ping ? false : true
    end
  end

  def up?
    pinged? && ssh_opened?
  end

  def down?
    not_pinged? && ssh_closed?
  end
end