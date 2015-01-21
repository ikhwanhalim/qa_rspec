require 'yaml'
require 'helpers/onapp_http'
require 'json'

class OnappRole
  include OnappHTTP
  attr_accessor :role_id, :permissions, :data

  def initialize
    auth unless self.conn
    @permissions = {}
    get_all_permissions
  end

  def create_role(label=nil, permission_ids=[])
    params = {}
    params[:role] = {:label => label,
                   :permission_ids => permission_ids
    }

    response = post("/roles", params)

    if response.has_key?('role')
      @role_id = response['role']['id']
      @data = response['role']
    else
      @data = response['errors']
    end
    return response
  end

  def create_user_role
    return create_role(label="UsersPermissions", permission_ids=get_users_permissions_ids)
  end

  def create_admin_role
    return create_role(label="AdminPermissions", permission_ids=get_admin_permissions_ids)
  end

  def remove_permission(permission)
    raise "Permission does not exist in role" unless @permissions.has_key?(permission)
    @data['permissions'].select! {|p| p['permission']['identifier'] != permission}
    ids = @data['permissions'].map {|p| p['permission']['id']}
    hash = {"role" => {"permission_ids" => ids}}
    put("/roles/#{@role_id}", hash)
    @data
  end

  def delete_role(data='')
    delete("/roles/#{@role_id}", data)
  end


  protected
  def get_all_permissions
    permissions = get("/permissions")
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