require 'net/http'
require 'resolv-replace'
require 'open3'
require 'cdn_resource'

module CdnDelivery
  def get_http_status(status_code, cname, params = nil, scheme = 'http', ssl_hostname = nil)
    if $deliveryOn == true
      count = 0
      # it is unstable to get the cname from the get()
      # it only pass 1 out of 3-5 times 
      while self.cname == '' and count < 10
        count += 1
        get()
        sleep(1)
      end

      # wait for x sec to avoid getting 400, does not work all the time
      # this is inefficient
      # cucumber BE waits for 90 secs, where it sets up all resource then wait for all resource config to be completed at once, thus it will not be time consuming
#      sleep(45)

      if ssl_hostname.nil?
        cmd = "curl -I #{scheme}://#{self.cname} #{params}"
      else
        cmd = "curl -I #{scheme}://#{ssl_hostname} #{params}"
      end

      # I think the loop can be omitted as long as we solve the issue above mentioned
      count = 0
      while count < 10
        output = Open3.capture3(cmd)
        arr = output[0].split("\r\n")
        count += 1

	# Lines below are arr content example
        # ["HTTP/1.1 200 OK",
        # "Server: nginx",
        # "Date: Mon, 13 Nov 2017 07:30:14 GMT",
        # "Content-Type: text/html",
        # "Content-Length: 5207",
        # "Connection: keep-alive",
        # "Last-Modified: Mon, 30 Oct 2017 09:14:35 GMT",
        # "ETag: \"1457-55cc011336ea6\"",
        # "Vary: Accept-Encoding",
        # "HTML: Yo",
        # "HTML2: Yo2",
        # "HTML3: Yo3",
        # "X-Cache: MISS",
        # "X-Storage: 50.7.99.69:8001",
        # "Accept-Ranges: bytes",
        # "X-Edge-IP: 50.7.99.69",
        # "X-Edge-Location: Los Angeles, US"]
        if !arr.empty? and arr[0].include? status_code
          puts "$deliveryOn is #{$deliveryOn}"
          return status_code
        elsif count == 9 and !arr.empty?
          return arr[0]
        elsif count == 9 and arr.empty?
          return output[2]
        end

      sleep(1)
      end
    else
      puts "$deliveryOn is #{$deliveryOn}"
    end
  end

  def get_rtmp_status(type, status, params = nil, token = nil)
    count = 0
    while cname == '' and count < 10
      count += 1
      get()
      sleep(1)
    end

    if type == 'STREAM_LIVE'
      cmd = "rtmpdump --rtmp 'rtmp://#{cname}' -B 10 -m 10 --app #{cdn_reference} --playpath 'stream_360p' #{params} -o /dev/null"
    else
      cmd = "rtmpdump --rtmp 'rtmp://#{cname}' -B 10 -m 10 --app #{cdn_reference} --playpath 'mp4:#{cdn_reference}/mp4.mp4#{token}' #{params} -o /dev/null"
    end

    count = 0

    sleep(60)

    while count < 10
      stdin, stdout, stderr, wait_thr = Open3.popen3(cmd)
      count += 1

      if wait_thr.value.exitstatus == status
        return wait_thr.value.exitstatus
      elsif count == 9
        return wait_thr.value.exitstatus
      end

    sleep(1)
    end
  end

  def cdn_common_pull_params
    {
      origin: "origin.mock.onappcdn.com"
    }
  end
end

