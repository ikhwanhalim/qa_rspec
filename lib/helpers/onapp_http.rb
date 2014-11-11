require 'mechanize'
require 'json'
require 'active_support/all'

module OnappHTTP
  attr_accessor :conn, :ip

  def auth(url, user, pass)
    @conn = Mechanize.new
    @headers = {'Accept' => 'application/json','Content-Type' => 'application/json'}
    @conn.add_auth(url, user, pass)
  end

  def get(url)
    JSON.parse @conn.get(url, @headers).body
    rescue Mechanize::ResponseCodeError => e
      JSON.parse e.page.body
  end

  def post(url, data="")
    puts data.to_json
    request = @conn.post(url, data.to_json, @headers)
    JSON.parse(request.body) unless request.body.blank?
    rescue Mechanize::ResponseCodeError => e
      JSON.parse e.page.body
  end

  def delete(url, data="")
    @conn.delete(url, data, @headers)
    rescue Mechanize::ResponseCodeError => e
      JSON.parse e.page.body
  end

  def put(url, data="")
    request = @conn.put(url, data.to_json, @headers)
    JSON.parse(request.body) unless request.body.blank?
    rescue Mechanize::ResponseCodeError => e
      JSON.parse e.page.body
  end
end
