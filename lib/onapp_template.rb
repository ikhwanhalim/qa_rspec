require 'helpers/onapp_http'
require 'helpers/template_manager'
require 'yaml'

class OnappTemplate  
  include TemplateManager
  include OnappHTTP
  include Hypervisor
  attr_reader :url
  attr_reader :allow_resize_without_reboot, :resize_without_reboot_policy, :allowed_hot_migrate, :allowed_swap, :id, :label, :min_disk_size
  attr_reader :min_memory_size, :operating_system, :operating_system_arch, :operating_system_distro, :state, :file_name
  
  def initialize(file_name)
    data = YAML::load_file('config/conf.yml')
    @url = data['url']
    @ip = data['ip']
    auth "#{@url}/users/sign_in", data['user'], data['pass']
        
#    get_template(file_name).each do |k, v|
#      instance_variable_set("@#{k}",v)
#      eigenclass = class<<self; self; end
#      eigenclass.class_eval do
#        attr_reader k
#      end
#    end

    template = get_template(file_name) 
    @allow_resize_without_reboot = template['allow_resize_without_reboot']
    @resize_without_reboot_policy = template['resize_without_reboot_policy']
    
    @allowed_hot_migrate = template['allowed_hot_migrate']
    @allowed_swap = template['allowed_swap']
    
    @id = template['id']
    @label = template['label']
    
    @min_disk_size = template['min_disk_size']
    @min_memory_size=template['min_memory_size']
    @operating_system=template['operating_system']
    @operating_system_arch=template['operating_system_arch']
    @operating_system_distro=template['operating_system_distro']
    @state = template['state']
    @file_name = template['file_name']
    
    @conn=nil
  end
    
end
