require 'mechanize'
require 'json'
require 'yaml'
require 'socket'
require 'uri'
require 'active_support/all'
require 'helpers/onapp_log'
require 'hashie'

module OnappHTTP
  attr_accessor :conn

  def auth(url: nil, user: nil, pass: nil)
    data = YAML::load_file('config/conf.yml')
    @url = url || data['url']
    @user = user || data['user']
    @pass = pass || data['pass']
    @ip = IPSocket::getaddress URI(@url).host
    @conn = Mechanize.new
    @conn.agent.allowed_error_codes += [403, 404, 406, 422]
    cookie = Mechanize::Cookie.new :domain=>@ip, :name => 'hide_market_logs', :value => '1', :path => '/'
    @conn.cookie_jar << cookie
    @headers = {'Accept' => 'application/json','Content-Type' => 'application/json'}
    Log.error("Password is nil") unless @pass
    @conn.add_auth("#{@url}/users/sign_in", @user, @pass)
  end

  def get(link, data="")
    Log.info("GET request is sending to #{link} with params #{data}")
    response = JSON.parse @conn.get("#{@url + link}.json", data, nil, @headers).body
    @conn.page.body = convert_to_mash(response)
  end

  def post(link, data="", additional='')
    request = @conn.post("#{@url + link}.json" + additional, data.to_json, @headers)
    Log.info("POST request is sending to #{link} with params #{data}")
    if request.body.blank?
      request
    else
      @conn.page.body = convert_to_mash(JSON.parse(request.body))
    end
  end

  def delete(link, data="")
    Log.info("DELETE request is sending to #{link} with params #{data}")
    @conn.delete("#{@url + link}.json", data, @headers)
  end

  def put(link, data="")
    request = @conn.put(@url + link + '.json', data.to_json, @headers)
    Log.info("PUT request is sending to #{link} with params #{data}")
    if request.body.blank?
      request
    else
      @conn.page.body = convert_to_mash(JSON.parse(request.body))
    end
  end

  private

  def convert_to_mash(data)
    if data.kind_of?(Array)
      data.map { |e| Hashie::Mash.new e }
    else
      Hashie::Mash.new data
    end
  end
end
