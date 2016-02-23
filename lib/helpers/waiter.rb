module Waiter
  def wait_until(max = 300, frequency = 1)
    Timeout.timeout(max) do
      until value = yield
        sleep(frequency)
      end
      value
    end
  end
end