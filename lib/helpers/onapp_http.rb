require 'mechanize'
require 'json'
require 'yaml'
require 'socket'
require 'uri'
require 'active_support/all'
require_relative 'onapp_log'

module OnappHTTP
  attr_accessor :conn

  def auth(url: nil, user: nil, pass: nil)
    data = YAML::load_file('config/conf.yml')
    @url = url || data['url']
    @user = user || data['user']
    @pass = pass || data['pass']
    @ip = IPSocket::getaddress URI(@url).host
    @conn = Mechanize.new
    cookie = Mechanize::Cookie.new :domain=>@ip, :name => 'hide_market_logs', :value => '1', :path => '/'
    @conn.cookie_jar << cookie
    @headers = {'Accept' => 'application/json','Content-Type' => 'application/json'}
    @conn.add_auth("#{url || @url}/users/sign_in", user || data['user'], pass || data['pass'])
  end

  def get(link, data="")
    request = JSON.parse @conn.get(@url + link + '.json', data, nil, @headers).body
    Log.info("GET request has been sent to #{link} with params #{data}")
    request
    rescue Mechanize::ResponseCodeError => e
      JSON.parse e.page.body
    rescue JSON::ParserError
      Log.warn("This is HTML page")
  end

  def post(link, data="")
    request = @conn.post(@url + link + '.json', data.to_json, @headers)
    Log.info("POST request has been sent to #{link} with params #{data}")
    request
    JSON.parse(request.body) unless request.body.blank?
    rescue Mechanize::ResponseCodeError => e
      JSON.parse e.page.body
  end

  def delete(link, data="")
    request = @conn.delete(@url + link + '.json', data, @headers)
    Log.info("DELETE request has been sent to #{link} with params #{data}")
    request
    rescue Mechanize::ResponseCodeError => e
      JSON.parse e.page.body
  end

  def put(link, data="")
    request = @conn.put(@url + link + '.json', data.to_json, @headers)
    Log.info("PUT request has been sent to #{link} with params #{data}")
    request
    JSON.parse(request.body) unless request.body.blank?
    rescue Mechanize::ResponseCodeError => e
      JSON.parse e.page.body
  end
end
