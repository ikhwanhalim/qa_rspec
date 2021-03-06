class FederationMarket
  include ApiClient, Waiter

  attr_accessor :federation_id
  attr_reader :federation, :resource

  def initialize(federation)
    @federation = federation
  end


  def set_preflight(status = false)
    put("/resource/#{federation_id}/set_preflight_status", {data: {status: status}})
    if status
       race_condition_check(false) { resource.preflight }
    else
      race_condition_check(true) { resource.preflight }
    end
  end

  def race_condition_check(state)
    output = (0..15).map { |_| sleep 0.2;yield }
    #TODO MKT-243
    #Log.error("RaceConditionError: preflight status has been changed immediately#{output}")
    set_preflight(!state) if output.include?(state)
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
