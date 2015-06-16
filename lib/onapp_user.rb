require 'yaml'
require 'helpers/onapp_http'
require 'helpers/transaction'
require 'json'
require 'helpers/template_manager'
require 'helpers/hypervisor'
require 'helpers/base_resources'

class OnappUser
  include OnappHTTP
  include Transaction
  include TemplateManager
  include Hypervisor
  include BaseResources

  attr_accessor :user_id, :data, :billing_details, :user_stats
  attr_reader :login, :password, :url

  def initialize(user: nil, pass: nil)
    if user && pass
      auth(user: user, pass: pass)
    else
      auth unless self.conn
    end
  end

  def create_user(data)
    params = {}
    params[:user] = data
    @login ||= params[:user][:login]
    @password ||= params[:user][:password]
    response = post("/users", params)
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
    put("/users/#{@user_id}", params)
  end

  def get_user_by_id(user_id=@user_id)
    response = get("/users/#{user_id}")
    if response['user']
      return response['user']
    else
      return response['errors']
    end
  end

  def get_user_billing_details(user_id=@user_id)
    data = get_user_by_id(user_id)
    @billing_details = {:total_amount => data['total_amount'].to_i,
                        :outstanding_amount => data['outstanding_amount'].to_i,
                        :payment_amount => data['payment_amount']
    }
  end

  def get_user_stat(user_id=@user_id)
    response = get("/users/#{user_id}/user_statistics")
    if response['user_stat']
      @user_stats = response['user_stat']
    else
      return response['errors']
    end
  end

  def login_as_user(id=nil)
    get("/users/#{id || @user_id}/login_as")
  end

  def delete_user(data='')
    delete("/users/#{@user_id}", data)
    wait_for_transaction(@user_id, "User", "destroy_user")
  end
end
