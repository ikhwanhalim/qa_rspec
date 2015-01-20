require 'yaml'
require 'helpers/onapp_http'
require 'json'

class OnappBilling
  include OnappHTTP
  attr_accessor :bp_id, :data

  def initialize
    auth unless self.conn
  end

  def create_billing_plan(data)
    params = {}
    params[:billing_plan] = data
    response = post("/billing_plans", params)

    if response['billing_plan']
      @bp_id = response['billing_plan']['id']
      @data = response['billing_plan']
    else
      @data = response['errors']
    end
  end

  def edit_billing_plan(data)
    params = {}
    params[:billing_plan] = data
    response = put("/billing_plans/#{@bp_id}", params)
    if !response.nil? and response.has_key?('errors')
      @data = response['errors']
    end
  end

  def get_billing_plan(bp_id)
    response = get("/billing_plans/#{bp_id}")
    if response['billing_plan']
      @data = response['billing_plan']
    else
      @data = response['errors']
    end
  end

  def delete_billing_plan
    delete("/billing_plans/#{@bp_id}")
  end
end
