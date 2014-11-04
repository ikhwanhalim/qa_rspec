require 'helpers/onapp_http'
require 'yaml'

class OnappTemplate
  include OnappHTTP
     
  def initialize(id)
    data = YAML::load_file('config/conf.yml')
    url = data['ip']
    auth "#{url}/users/sign_in", data['login'], data['password']
    data = get("#{url}/templates/#{id}.json")
    data['image_template'].each do |k, v|
      instance_variable_set("@#{k}",v)
      eigenclass = class<<self; self; end
      eigenclass.class_eval do
        attr_reader k
      end
    end                
  end
    
end
