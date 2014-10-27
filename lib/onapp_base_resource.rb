require 'yaml'
require 'helpers/onapp_http'
require 'json'
require 'onapp_billing'

class OnappBaseResource
  include OnappHTTP
  attr_accessor :br_id

  def initialize
    config = YAML::load_file('./config/conf.yml')
    @ip = config['cp']['ip']
    user = config['cp']['admin_user']
    pass = config['cp']['admin_pass']
    auth("#{@ip}/users/sign_in", user, pass)

  end

  def create_base_resource(bp_id, data)
    data = {"base_resource" => data}
    puts data
    response = post("#{@ip}/billing_plans/#{bp_id}/base_resources.json", data)

    if !response.has_key?('errors')
      @br_id = response['base_resource']['id']
    end
    return response
  end

  def edit_base_resource(bp_id, br_id, data)
    data = {"base_resource" => data}
    puts data
    response = put("#{@ip}/billing_plans/#{bp_id}/base_resources/#{br_id}.json", data)
  end

  def get_base_resource(bp_id, br_id)
    response = get("#{@ip}/billing_plans/#{bp_id}/base_resources/#{br_id}.json")
  end

  def delete_base_resource(bp_id, br_id)
    response = delete("#{@ip}/billing_plans/#{bp_id}/base_resources/#{br_id}.json")
  end
end
