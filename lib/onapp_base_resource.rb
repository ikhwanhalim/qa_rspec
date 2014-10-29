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
    @zones_data = {
        :backup => {
            :url => 'settings/backup_server_zones.json',
            :tag => "backup_server_group"
        },
        :store => {
            :url => 'settings/data_store_zones.json',
            :tag => 'data_store_group'
        },
        :edge => {
            :url => 'edge_groups.json',
            :tag => 'edge_group'
        },
        :hypervisor => {
            :url => 'settings/hypervisor_zones.json',
            :tag => 'hypervisor_group'
        },
        :network => {
            :url => 'settings/network_zones.json',
            :tag => 'network_group'
        },
        :recipe => {
            :url => 'recipe_groups.json',
            :tag => ''
        },
        :template => {
            :url => 'template_store.json',
            :tag => ''
        }
    }

  end

  def create_base_resource(bp_id, data)
    data = {:base_resource => data}
    response = post("#{@ip}/billing_plans/#{bp_id}/base_resources.json", data)

    if !response.has_key?('errors')
      @br_id = response['base_resource']['id']
    end
    return response
  end

  def edit_base_resource(bp_id, br_id, data)
    data = {:base_resource => data}
    put("#{@ip}/billing_plans/#{bp_id}/base_resources/#{br_id}.json", data)
  end

  def get_base_resource(bp_id, br_id)
    get("#{@ip}/billing_plans/#{bp_id}/base_resources/#{br_id}.json")
  end

  def delete_base_resource(bp_id, br_id)
    delete("#{@ip}/billing_plans/#{bp_id}/base_resources/#{br_id}.json")
  end

  def get_zone_id(type=nil)
    response = get("#{@ip}/#{@zones_data[type][:url]}")
    if @zones_data[type][:tag] == ''
      id = response.first['id']
    elsif
      id = response.first[@zones_data[type][:tag]]['id']
    end
    return id

  end
end
