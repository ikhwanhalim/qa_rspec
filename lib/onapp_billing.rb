require 'yaml'
require 'helpers/onapp_http'
require 'json'

class OnappBilling
  include OnappHTTP
  attr_accessor :bp_id, :data

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
    response = post("#{@url}/billing_plans.json", params)

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
    response = put("#{@url}/billing_plans/#{@bp_id}.json", params)
    if !response.nil? and response.has_key?('errors')
      @data = response['errors']
    end
  end

  def get_billing_plan(bp_id)
    response = get("#{@url}/billing_plans/#{bp_id}.json")
    if response['billing_plan']
      @data = response['billing_plan']
    else
      @data = response['errors']
    end
  end

  def delete_billing_plan
    delete("#{@url}/billing_plans/#{@bp_id}.json")
  end
end
