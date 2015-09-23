require 'helpers/onapp_http'

class FederationMarket
  include OnappHTTP

  def initialize
    data = YAML::load_file('config/conf.yml')
    auth url: data['market']['url'], user: data['market']['user'], pass: data['market']['pass']
  end

  def set_reflight(status: true)

  end
end