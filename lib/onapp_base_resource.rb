require 'yaml'
require 'helpers/onapp_http'
require 'json'
require 'onapp_billing'

class OnappBaseResource
  include OnappHTTP
  attr_accessor :br_id, :data

  def initialize
    auth unless self.conn
    @zones_data = {
        :backup => {
            :url => 'settings/backup_server_zones',
            :tag => "backup_server_group"
        },
        :store => {
            :url => 'settings/data_store_zones',
            :tag => 'data_store_group'
        },
        :edge => {
            :url => 'edge_groups',
            :tag => 'edge_group'
        },
        :hypervisor => {
            :url => 'settings/hypervisor_zones',
            :tag => 'hypervisor_group'
        },
        :network => {
            :url => 'settings/network_zones',
            :tag => 'network_group'
        },
        :recipe => {
            :url => 'recipe_groups',
            :tag => ''
        },
        :template => {
            :url => 'template_store',
            :tag => ''
        }
    }

  end

  def create_base_resource(bp_id, data)
    params = {}
    params[:base_resource] = data
    Log.info("Creating base resource: \n #{params}")
    response = post("/billing_plans/#{bp_id}/base_resources", params)

    if response.has_key?('base_resource')
      @br_id = response['base_resource']['id']
      @data = response['base_resource']
    else
      @data = response['errors']
    end
  end

  def edit_base_resource(bp_id, br_id, data)
    params = {}
    params[:base_resource] = data
    response = put("/billing_plans/#{bp_id}/base_resources/#{br_id}", params)
    if !response.nil? and response.has_key?('errors')
      @data = response['errors']
    end
  end

  def get_base_resource(bp_id, br_id)
    response = get("/billing_plans/#{bp_id}/base_resources/#{br_id}")
    if response.has_key?('base_resource')
      @data = response['base_resource']
    else
      @data = response['errors']
    end
  end

  def delete_base_resource(bp_id, br_id, data = '')
    response = delete("/billing_plans/#{bp_id}/base_resources/#{br_id}", data)
    puts response
    if response.is_a?(Hash) and response.has_key?('errors')
      @data = response['errors']
    end
  end

  def get_zone_id(type=nil)
    response = get("/#{@zones_data[type][:url]}")
    if @zones_data[type][:tag] == ''
       id = response.first['id']
    else
       id = response.first[@zones_data[type][:tag]]['id']
    end
    return id
  end

  # For min IOPS base resources
  def dsz_zone_id_by_type(type=nil)
    dsz = nil
    data_stores = get("/settings/data_stores")
    data_stores.each do |data_store|
      if data_store['data_store']['data_store_type'] == type
        dsz = data_store['data_store']['data_store_group_id']
        break
      end
    end
    return dsz
  end
end
