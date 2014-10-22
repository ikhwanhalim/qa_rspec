require 'mechanize'
require 'json'

module OnappHTTP
  attr_accessor :conn, :ip

  def auth(url, user, pwd)
    @conn = Mechanize.new
    @conn.add_auth(url, user, pwd)
  end

  def get(url)
    JSON.parse @conn.get(url).body
  end

  def post(url, data="")
    curl = @conn.post(url, data.to_json, {'Content-Type' => 'application/json'})
    JSON.parse(curl.body)
  end

  def delete(url)
    @conn.delete(url)
  end
end