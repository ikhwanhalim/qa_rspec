require "helpers/curl"
require "helpers/parser"

class OnappRole
  include Curl
  include Parser

  attr_reader :id, :label, :role_permissions

  def initialize_permissions
    class << self
      @@all_permissions.each do |name, id|
        attr_reader name
        define_method("#{name}=") do |val|
          instance_variable_set("@#{name}", val)
        end
      end
    end
  end

  def add(id)
    get_all_permissions
    initialize_permissions
    data = from_api(get("/roles/#{id}"))
    @id = data[:id]
    @label = data[:label]
    @role_permissions = permission_filter(data[:permissions])
    @role_permissions.each do |name, id|
      instance_variable_set("@#{name}", true)
    end
    return self
  end 

  def add_role_permissions(names)
    names.each do |name|
      @role_permissions[name] = @@all_permissions[name]
      instance_variable_set("@#{name}", true)
    end
    put("/roles/#{@id}", to_api(:role => to_api({"permission_ids"=>@role_permissions.values})))
  end

  def remove_role_permissions(names)
    names.each do |name|
      @role_permissions.delete(name)
      instance_variable_set("@#{name}", false)
    end
    put("/roles/#{@id}", to_api(:role => to_api({"permission_ids"=>@role_permissions.values})))
  end

  def get_all_permissions
    @@all_permissions = permission_filter(from_api(get("/permissions")))
  end

  def permission_filter(permissions)
    hash = {}
    permissions.each do |p|
      permission_name = p["permission"]["identifier"].gsub(/\./,"_")
      permission_id = p["permission"]["id"]
      tmp = { permission_name => permission_id }
      hash.merge! tmp
    end
    return hash
  end
end