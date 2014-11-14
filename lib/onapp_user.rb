require 'yaml'
require 'helpers/onapp_http'
require 'json'

class OnappUser
  include OnappHTTP
  attr_accessor :user_id

  def initialize(user=nil, pass=nil)
    config = YAML::load_file('./config/conf.yml')
    @ip = config['cp']['ip']
    @user = user ? user : config['cp']['admin_user']
    @pass = pass ? pass : config['cp']['admin_pass']
    auth("#{@ip}/users/sign_in", @user, @pass)
  end

  def create_user(data)
    data = {"user" => data}
    response = post("#{@ip}/users.json", data)

    if !response.has_key?('errors')
      @user_id = response['user']['id']
    end
    return response
  end

  def edit_user(user_id, data)
    data = {"user" => data}
    put("#{@ip}/users/#{user_id}.json", data)
  end

  def get_user_by_id(user_id)
    get("#{@ip}/users/#{user_id}.json")
  end

  def delete_user(user_id, data='')
    delete("#{@ip}/users/#{user_id}.json", data)
  end
end
