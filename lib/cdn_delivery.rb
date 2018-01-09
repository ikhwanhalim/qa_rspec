require 'net/http'

module CdnDelivery
  def get_http_status(cname, scheme = 'http', ssl_hostname = nil)
    if $deliveryOn == true
      count = 0
      # it is unstable to get the cname from the get()
      # it only pass 1 out of 3-5 times 
      while self.cname == '' and count < 10
        count += 1
        get()
        sleep(1)
      end

      file = "files/file.txt"
      uri = URI("#{scheme}://#{self.cname}/#{file}")
      res = Net::HTTP.get_response(uri)
      return res.code
    end
  end

  def cdn_common_pull_params
    {
      origin: "origin.mock.onappcdn.com"
    }
  end
end

