module Network
  include Waiter

  def is_port_opened?(port = 22)
    Log.info("Connect to: #{ip_address}:#{port}")
    wait_until(300) do
      begin
        TCPSocket.new(ip_address, port).close
      rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
        false
      end
      return true
    end
  end

  def is_port_closed?(port = 22)
    Log.info("Connect to: #{ip_address}:#{port}")
    wait_until(300) do
      begin
        TCPSocket.new(ip_address, port).close
      rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
        return true
      end
      false
    end
  end

  #TODO fix if server non-reachble
  def pinged?
    Log.info("Ping IP address: #{ip_address}")
    host = Net::Ping::External.new(ip_address)
    wait_until { host.ping? ? true : false }
  end

  def not_pinged?
    Log.info("Ping IP address: #{ip_address}")
    host = Net::Ping::External.new(ip_address)
    wait_until { host.ping? ? false : true }
  end

  def up?
    pinged? && is_port_opened?
  end

  def down?
    not_pinged? && is_port_closed?
  end
end