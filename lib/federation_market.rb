require 'helpers/onapp_http'
require 'federation'

class FederationMarket
  include OnappHTTP

  attr_reader :federation_id

  def initialize(federation_id)
    @federation_id = federation_id
    data = YAML::load_file('config/conf.yml')
    auth url: data['market']['url'], user: data['market']['user'], pass: data['market']['pass']
  end

  def set_preflight(status = false)
    put("/resource/#{federation_id}/set_preflight_status", {data: {status: status}})
  end
end
