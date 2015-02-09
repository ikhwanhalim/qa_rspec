require 'yaml'
require 'helpers/onapp_http'
require 'virtual_machine/vm_base'

class OnappTrader < VirtualMachine
  include OnappHTTP
  attr_accessor :subscribed_zone

  def initialize
    data = YAML::load_file('config/conf.yml')
    url = data['trader']['url']
    user = data['trader']['user']
    pass = data['trader']['pass']
    ip = data['trader']['ip']
    auth url: url, user: user, pass: pass
    cookie = Mechanize::Cookie.new :domain=>ip, :name => 'hide_market_logs', :value => '1', :path => '/'
    @conn.cookie_jar << cookie
  end

  def subscribe(federation_id)
    data = {'hypervisor_zone_namer' =>
                {'hypervisor_group_label' => federation_id,
                 'hypervisor_label' => federation_id,
                 'data_store_group_label' => federation_id,
                 'data_store_label' => federation_id,
                 'network_group_label' => federation_id,
                 'network_label' => federation_id,
                 'image_template_group_label' => federation_id,
                }
    }
    response = post("/federation/hypervisor_zones/#{federation_id}/subscribe", data)
    return response if response
    @subscribed_zone = all_subscribed.select {|z| z['federation_id'] == federation_id}.first
  end

  def all_unsubscribed
    zones = get "/federation/hypervisor_zones/unsubscribed"
    zones.map! { |z| z["hypervisor_zone"]}
  end

  def all_subscribed
    zones = get "/settings/hypervisor_zones"
    zones.map! { |z| z["hypervisor_group"]}
    zones.delete_if { |z| z['federation_id'] == nil }
  end

  def unsubscribe_all
    all_subscribed.each do |z|
      delete("/federation/hypervisor_zones/#{z['id']}/unsubscribe")
    end
  end

  def get_all(resource)
    get(resource)
  end

  # Get resources for building VM
  def building_resources(template_label, federation_id)
    hypervisors = get('/settings/hypervisors').select {|h| h['hypervisor']['label'] == federation_id}
    templates = get('/templates/all').select do |t|
      t['image_template']['remote_id'] &&
        t['image_template']['remote_id'].include?(federation_id) &&
        t['image_template']['label'] == template_label
    end
    hypervisor = hypervisors.first['hypervisor']
    template = templates.first['image_template']
    {'hypervisor' => hypervisor, 'template' => template}
  end
end