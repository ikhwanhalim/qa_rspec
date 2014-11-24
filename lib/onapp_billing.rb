require 'yaml'
require 'helpers/onapp_http'
require 'json'

class OnappBilling
  include OnappHTTP
  attr_accessor :bp_id

  def initialize
    config = YAML::load_file('./config/conf.yml')
    @url = config['url']
    @user = config['user']
    @pass = config['pass']
    auth("#{@url}/users/sign_in", @user, @pass)
  end

  def create_billing_plan(data)
    params = {}
    params[:billing_plan] = data
    puts params
    response = post("#{@url}/billing_plans.json", params)

    if !response.has_key?('errors')
      @bp_id = response['billing_plan']['id']
    end
    return response
  end

  def edit_billing_plan(bp_id, data)
    params = {}
    params[:billing_plan] = data
    put("#{@url}/billing_plans/#{bp_id}.json", params)
  end

  def get_billing_plan(bp_id)
    get("#{@url}/billing_plans/#{bp_id}.json")
  end

  def delete_billing_plan(bp_id)
    delete("#{@url}/billing_plans/#{bp_id}.json")
  end
end
