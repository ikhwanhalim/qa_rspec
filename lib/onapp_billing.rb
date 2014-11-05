require 'yaml'
require 'helpers/onapp_http'
require 'json'

class OnappBilling
  include OnappHTTP
  attr_accessor :bp_id

  def initialize
    config = YAML::load_file('./config/conf.yml')
    @ip = config['cp']['ip']
    user = config['cp']['admin_user']
    pass = config['cp']['admin_pass']
    auth("#{@ip}/users/sign_in", user, pass)
  end

  def create_billing_plan(data)
    data = {"billing_plan" => data}
    response = post("#{@ip}/billing_plans.json", data)

    if !response.has_key?('errors')
      @bp_id = response['billing_plan']['id']
    end
    return response
  end

  def edit_billing_plan(bp_id, data)
    data = {"billing_plan" => data}
    put("#{@ip}/billing_plans/#{bp_id}.json", data)
  end

  def get_billing_plan(bp_id)
    get("#{@ip}/billing_plans/#{bp_id}.json")
  end

  def delete_billing_plan(bp_id)
    delete("#{@ip}/billing_plans/#{bp_id}.json")
  end
end
