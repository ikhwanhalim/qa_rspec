require_relative 'waiter'

module Network
  include Waiter

  def port_opened?(port = 22)
    Log.info("Connect to: #{ip_address}:#{port}")
    wait_until do
      begin
        TCPSocket.new(ip_address, port).close
        return true
      rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH, Errno::ETIMEDOUT
        false
      end
    end
  end

  def port_closed?(port = 22)
    Log.info("Connect to: #{ip_address}:#{port}")
    wait_until do
      begin
        TCPSocket.new(ip_address, port).close
        false
      rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH, Errno::ETIMEDOUT
        return true
      end
    end
  end

  def pinged?
    Log.info("Ping IP address: #{ip_address}")
    wait_until do
      system("ping -c1 #{ip_address}")
    end
  end

  def not_pinged?
    Log.info("Ping IP address: #{ip_address}")
    wait_until do
      system("ping -c1 #{ip_address}") ? false : true
    end
  end

  def up?
    pinged? && port_opened?
  end

  def down?
    not_pinged? && port_closed?
  end
end