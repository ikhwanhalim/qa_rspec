require 'yaml'
require 'helpers/onapp_http'
require 'json'

class OnappBilling
  include OnappHTTP
  attr_accessor :bp_id

  def initialize
    config = YAML::load_file('./config/conf.yml')
    @ip = config['cp']['ip']
    auth("#{@ip}/users/sign_in", "admin", "changeme")
  end

  def create_billing_plan(data)
    data = {"billing_plan" => data}
    puts data
    response = post("#{@ip}/billing_plans.json", data)

    if !response.has_key?('errors')
      @bp_id = response['billing_plan']['id']
    end
    return response
  end

  def edit_billing_plan(bp_id, data)
    data = {"billing_plan" => data}
    puts data
    response = put("#{@ip}/billing_plans/#{bp_id}.json", data)
  end

  def get_billing_plan(bp_id)
    response = get("#{@ip}/billing_plans/#{bp_id}.json")
  end

  def delete_billing_plan(bp_id)
    response = delete("#{@ip}/billing_plans/#{bp_id}.json")
  end
end
