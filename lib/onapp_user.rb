require 'yaml'
require 'helpers/onapp_http'
require 'json'

class OnappUser
  include OnappHTTP
  attr_accessor :user_id
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

    if !response.has_key?('errors')
      @user_id = response['user']['id']
    end
    return response
  end

  def edit_user(user_id, data)
    params = {}
    params[:user] = data
    put("#{@url}/users/#{user_id}.json", params)
  end

  def get_user_by_id(user_id)
    get("#{@url}/users/#{user_id}.json")
  end

  def delete_user(user_id, data='')
    delete("#{@url}/users/#{user_id}.json", data)
    attempt = 0
    while attempt < 10 do
      response = get_user_by_id(user_id)
      break if response.has_key?('errors')
      attempt += 1
    end
  end
end
