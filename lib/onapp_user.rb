require 'yaml'
require 'helpers/onapp_http'
require 'helpers/transaction'
require 'json'

class OnappUser
  include OnappHTTP
  include Transaction
  attr_accessor :user_id, :data
  attr_reader :login, :password

  def initialize(user=nil, pass=nil)
    config = YAML::load_file('./config/conf.yml')
    @url = config['url']
    @user ||= config['user']
    @pass ||= config['pass']
    auth("#{@url}/users/sign_in", @user, @pass)
  end

  def create_user(data)
    params = {}
    params[:user] = data
    @login ||= params[:user][:login]
    @password ||= params[:user][:password]
    response = post("#{@url}/users.json", params)
    if response['user']
      @user_id = response['user']['id']
      @data = response['user']
    else
      @data = response['errors']
    end
  end

  def edit_user(data)
    params = {}
    params[:user] = data
    put("#{@url}/users/#{@user_id}.json", params)
  end

  def get_user_by_id(user_id)
    response = get("#{@url}/users/#{user_id}.json")
    if response['user']
      return response['user']
    else
      return response['errors']
    end
  end

  def delete_user(data='')
    delete("#{@url}/users/#{@user_id}.json", data)
    wait_for_transaction(@user_id, "User", "destroy_user")
  end
end
