require 'helpers/api_client'
require 'helpers/waiter'
require 'logger'

class FederationMarket
  include ApiClient, Waiter

  attr_accessor :federation_id
  attr_reader :federation, :resource

  def initialize(federation)
    @federation = federation
  end


  def set_preflight(status = false)
    put("/resource/#{federation_id}/set_preflight_status", {data: {status: status}})
  end

  def resource
    get("/resource/#{federation_id}").data
  end

  def wait_for_zone_publishing
    wait_until do
      resource
    end
  end
end
