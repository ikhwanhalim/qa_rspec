require 'net/http'
require 'net/ftp'

module CdnDelivery
  def get_http_status(cname, scheme = 'http', ssl_hostname = nil)
    if $deliveryOn == true
      count = 0
      # it is unstable to get the cname from the get()
      # it only pass 1 out of 3-5 times 
      while self.cname == '' and count < 10
        count += 1
        get()
        binding.pry
        sleep(1)
      end

      file = "files/file.txt"
      uri = URI("#{scheme}://#{self.cname}/#{file}")
      res = Net::HTTP.get_response(uri)
      binding.pry
      return res.code
    end
  end

  def cdn_common_pull_params
    {
      origin: "origin.mock.onappcdn.com"
    }
  end
  
  def cdn_common_push_params
    {
      ftp_password: "dVm823Rt3Gcq55yY8rDg"
    }
  end

  def cdn_upload_file(file, host)
    uri = URI.parse('ftp://' + host)
 
    ftp = Net::FTP.new
    ftp.connect(uri.host, uri.port)
    ftp.passive = true
    ftp.login(uri.user, uri.password)
    new_dir = ftp.mkdir(uri.path)
    ftp.chdir(uri.path)
    ftp.putbinaryfile(file)
    ftp.close

    true

    rescue Exception => err
      puts err.message
      false
  end
end

