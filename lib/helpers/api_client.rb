require 'active_support/all'
require_relative 'service_checker'

module ApiClient
  include ServiceChecker

  CONF = ENV['CONF_PATH'] || 'config/conf.yml'

  attr_reader :ip

  def conn
    unless @conn
      read_config
      setup_connection
      check_services if authorize_for != 'market'
    end
    @conn
  end

  def read_config
    data = YAML::load_file(CONF)
    name = authorize_for
    @url = name ? data[name]['url'] : data['url']
    @user = name ? data[name]['user'] : data['user']
    @pass = name ? data[name]['pass'] : data['pass']
    @ip = IPSocket::getaddress URI(@url).host
    Log.error("Some credentials are not defined") if !@pass || !@url || !@user
  end

  def setup_connection
    @conn = Mechanize.new
    @conn.agent.allowed_error_codes += [403, 404, 406, 422]
    cookie = Mechanize::Cookie.new :domain=>@ip, :name => 'hide_market_logs', :value => '1', :path => '/'
    @conn.cookie_jar << cookie
    @headers = {'Accept' => 'application/json','Content-Type' => 'application/json'}
    @conn.add_auth("#{@url}/users/sign_in", @user, @pass)
  end

  def authorize_for
    name = self.class.to_s.split(/(?=[A-Z])/).last.downcase
    %(supplier trader market).include?(name) ? name : nil
  end

  def get(link, data="")
    Log.info("GET request is sending to #{link} #{'with params ' + data.to_s unless data.empty?}")
    response = JSON.parse conn.get("#{@url + link}.json", data, nil, @headers).body
    conn.page.body = convert_to_mash(response)
  end

  def get_from_url(link, data="")
    Log.info("GET request is sending to #{link} #{'with params ' + data.to_s unless data.empty?}")
    response = JSON.parse conn.get(link, data, nil, @headers).body
    conn.page.body = convert_to_mash(response)
  end

  def post(link, data="", additional='')
    request = conn.post("#{@url + link}.json" + additional, data.to_json, @headers)
    Log.info("POST request is sending to #{link} #{'with params ' + data.to_s unless data.empty?}")
    if request.body.blank?
      request
    else
      conn.page.body = convert_to_mash(JSON.parse(request.body))
      if conn.agent.allowed_error_codes.include?(request.code.to_i)
        Log.warn("Response on POST request is: #{request.body} and response code is: #{request.code.to_i}")
      end
      conn.page.body
    end
  end

  def delete(link, data="")
    Log.info("DELETE request is sending to #{link} #{'with params ' + data.to_s unless data.empty?}")
    conn.delete("#{@url + link}.json", data, @headers)
  end

  def put(link, data="")
    request = conn.put(@url + link + '.json', data.to_json, @headers)
    Log.info("PUT request is sending to #{link} #{'with params ' + data.to_s unless data.empty?}")
    if request.body.blank?
      request
    else
      conn.page.body = convert_to_mash(JSON.parse(request.body))
    end
  end

  def version
    @version ||= get('/version').version.to_f
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
