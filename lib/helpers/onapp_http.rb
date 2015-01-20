require 'mechanize'
require 'json'
require 'yaml'
require 'active_support/all'
require_relative 'onapp_log'

module OnappHTTP
  attr_accessor :conn

  def auth(url: nil, user: nil, pass: nil)
    data = YAML::load_file('config/conf.yml')
    @url = url || data['url']
    @user = user || data['user']
    @pass = pass || data['pass']
    @ip = data['ip']
    @conn = Mechanize.new
    @headers = {'Accept' => 'application/json','Content-Type' => 'application/json'}
    @conn.add_auth("#{url || @url}/users/sign_in", user || data['user'], pass || data['pass'])
  end

  def get(link, data="")
    JSON.parse @conn.get(@url + link + '.json', data, nil, @headers).body
    rescue Mechanize::ResponseCodeError => e
      JSON.parse e.page.body
    rescue JSON::ParserError
      nil
  end

  def post(link, data="")
    request = @conn.post(@url + link + '.json', data.to_json, @headers)
    JSON.parse(request.body) unless request.body.blank?
    rescue Mechanize::ResponseCodeError => e
      JSON.parse e.page.body
  end

  def delete(link, data="")
    @conn.delete(@url + link + '.json', data, @headers)
    rescue Mechanize::ResponseCodeError => e
      JSON.parse e.page.body
  end

  def put(link, data="")
    request = @conn.put(@url + link + '.json', data.to_json, @headers)
    JSON.parse(request.body) unless request.body.blank?
    rescue Mechanize::ResponseCodeError => e
      JSON.parse e.page.body
  end
end
