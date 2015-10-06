require 'helpers/api_client'
require 'federation'
require 'helpers/waiter'
require 'singleton'

class FederationMarket
  include Singleton, ApiClient, Waiter

  attr_reader :federation_id

  def initialize
    data = YAML::load_file('config/conf.yml')
    auth url: data['market']['url'], user: data['market']['user'], pass: data['market']['pass']
  end

  def set_preflight(status = false)
    put("/resource/#{federation_id}/set_preflight_status", {data: {status: status}})
  end

  def wait_for_zone_publishing
    wait_until do
      get("/resource/#{federation_id}").data ? true : false
    end
  end
end
