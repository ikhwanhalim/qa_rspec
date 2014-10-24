require 'mechanize'
require 'json'
require 'active_support/all'

module OnappHTTP
  attr_accessor :conn, :ip

  def auth(url, user, pass)
    @conn = Mechanize.new
    @conn.add_auth(url, user, pass)
  end

  def get(url)
    JSON.parse @conn.get(url).body
    rescue Mechanize::ResponseCodeError => e
      JSON.parse e.page.body
  end

  def post(url, data="")
    request = @conn.post(url, data.to_json, {'Content-Type' => 'application/json'})
    JSON.parse(request.body) unless request.body.blank?
    rescue Mechanize::ResponseCodeError => e
      JSON.parse e.page.body
  end

  def delete(url)
    @conn.delete(url)
    rescue Mechanize::ResponseCodeError => e
      JSON.parse e.page.body
  end
end
