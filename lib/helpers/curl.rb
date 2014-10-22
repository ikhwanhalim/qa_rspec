require 'helpers/cmd'

module Curl

  def self.run(x, url="", opt="", tourl="")
    if (defined? $current_user).nil?
      user = $cp.admin
    else
      user = $current_user
    end

    @base="curl -s -i -X #{x} -u '#{user}' -H 'Accept: application/#{$cp.api_type}' -H 'Content-type: application/#{$cp.api_type}' --url http://#{$cp.ip}/#{url}.#{$cp.api_type}#{tourl}" # -d '#{opt}'"
    #p @base
    if opt.empty?
      res = Cmd.execute(@base)
    else
      res = Cmd.execute("#{@base} -d '#{opt}'")
    end
    if RUBY_VERSION.include?("1.9")
      #@status = !!(res.split("\n").grep(/Status/).first.gsub(/^.* /, "").gsub(/\n/, "").to_i < 205)
      @status = !!(res.split("\n").grep(/Status/).first.split(' ')[1].to_i < 205)
    else
      @status = !!(res.lines.grep(/Status/).first.gsub(/^.* /, "").gsub(/\n/, "").to_i < 205)
    end
    if Curl::status
      res
    else
      raise ("Unexpected curl status \n #{res}")
    end

  end

  def self.status
    @status
  end

  def status?
    Curl::status
  end

  def post(url="", opt="", tourl="")
    p "from POST!  url #{url}  #{opt} #{tourl}"
    Curl::run("POST", url, opt, tourl)
  end
  def put(url="", opt="", tourl="")
    Curl::run("PUT", url, opt, tourl)
  end

  def get(url="", opt="",  tourl="")
    Curl::run("GET", url, opt, tourl)
  end

  def delete(url="", opt="", tourl="")
    Curl::run("DELETE", url, opt, tourl)
  end



end
