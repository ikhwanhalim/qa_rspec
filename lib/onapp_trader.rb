require 'yaml'
require 'helpers/onapp_http'

class OnappTrader
  include OnappHTTP
  attr_accessor :subscribed_zone

  def initialize
    data = YAML::load_file('config/conf.yml')
    data['trader'].each do |k, v|
      instance_variable_set("@#{k}",v)
      eigenclass = class<<self; self; end
      eigenclass.class_eval do
        attr_accessor k
      end
    end
    auth "#{@url}/users/sign_in", @user, @pass
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
    response = post("#{@url}/federation/hypervisor_zones/#{federation_id}/subscribe.json", data)
    return response if response
    @subscribed_zone = all_subscribed.select {|z| z['federation_id'] == federation_id}.first
  end

  def all_unsubscribed
    zones = get "#{@url}/federation/hypervisor_zones/unsubscribed.json"
    zones.map! { |z| z["hypervisor_zone"]}
  end

  def all_subscribed
    zones = get "#{@url}/settings/hypervisor_zones.json"
    zones.map! { |z| z["hypervisor_group"]}
    zones.delete_if { |z| z['federation_id'] == nil }
  end

  def unsubscribe_all
    all_subscribed.each do |z|
      delete("#{@url}/federation/hypervisor_zones/#{z['id']}/unsubscribe.json")
    end
  end
end