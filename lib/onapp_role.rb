require 'yaml'
require 'helpers/onapp_http'
require 'json'

class OnappRole
  include OnappHTTP
  attr_accessor :role_id, :permissions

  def initialize(user=nil, pass=nil)
    config = YAML::load_file('./config/conf.yml')
    @url = config['url']
    @user ||= config['user']
    @pass ||= config['pass']
    auth("#{@url}/users/sign_in", @user, @pass)
    @permissions = {}
    get_all_permissions
  end

  def create_role(label=nil, permission_ids=[])
    data = {
        "role" => {
            "label" => label,
            "permission_ids" => permission_ids
        }
    }
    response = post("#{@url}/roles.json", data)

    if !response.has_key?('errors')
      @role_id = response['role']['id']
    end
    return response
  end

  def create_user_role
    return create_role(label="UsersPermissions", permission_ids=get_users_permissions_ids)
  end

  def create_admin_role
    return create_role(label="AdminPermissions", permission_ids=get_admin_permissions_ids)
  end

  def delete_role(role_id, data='')
    delete("#{@url}/roles/#{role_id}.json", data)
    attempt = 0
    while attempt < 10 do
      response = get("#{@url}/roless/#{role_id}.json")
      break if response.has_key?('errors')
      attempt += 1
    end
  end


  protected
  def get_all_permissions
    permissions = get("#{@url}/permissions.json")
    permissions.each do |permission|
      @permissions[permission['permission']['identifier']] = permission['permission']['id']
    end
  end

  # Testing version of method
  def get_users_permissions_ids
    users_permissions = []
    @permissions.each do |identifier, id|
      if identifier.include? '.create' or
          identifier.include? '.own' or
          identifier.include? '.read' or
          identifier.include? '.list'
        users_permissions.append(id)
      end
    end
    return users_permissions
  end

  # Testing version of method
  def get_admin_permissions_ids
    admin_permissions = []
    @permissions.each do |identifier, id|
      if !identifier.include? '.'
        admin_permissions.append(id)
      end
    end
    return admin_permissions
  end

end