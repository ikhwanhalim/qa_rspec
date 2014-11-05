require 'helpers/onapp_http'
require 'helpers/template_manager'
require 'helpers/hypervisor'
require 'yaml'

class OnappTemplate
  include OnappHTTP
  include TemplateManager
  include Hypervisor
  attr_reader :url
     
  def initialize(file_name)
    data = YAML::load_file('config/conf.yml')
    @url = data['url']
    @ip = data['ip']
    auth "#{@url}/users/sign_in", data['user'], data['pass']
    get_template(file_name).each do |k, v|
      instance_variable_set("@#{k}",v)
      eigenclass = class<<self; self; end
      eigenclass.class_eval do
        attr_reader k
      end
    end
  end
    
end
