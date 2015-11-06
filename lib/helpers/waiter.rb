module Waiter
  def wait_until(max = 30)
    Timeout.timeout(max) do
      until value = yield
        sleep(1)
      end
      value
    end
  end
end