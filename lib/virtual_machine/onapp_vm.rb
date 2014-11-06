require 'helpers/onapp_http'
require 'helpers/hypervisor'
require 'helpers/template_manager'
require 'onapp_template'
require 'yaml'

class VirtualMachine  
  include OnappHTTP
  include Hypervisor  
  
  attr_reader :hypervisor_id, :template
  
  def initialize(template,virtualization,user=nil)
    data = YAML::load_file('config/conf.yml')
    @url = data['url']
    @ip = data['ip']
    auth "#{@url}/users/sign_in", data['user'], data['pass']        
    @template = OnappTemplate.new template    
    @hypervisor_id = for_vm_creation(virtualization)
    
    if !user.nil?
      @conn=nil      
      auth "#{@url}/users/sign_in", user.login, user.password
    end
              
  end
end