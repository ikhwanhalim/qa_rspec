require 'helpers/onapp_http'
require 'helpers/hypervisor'
require 'helpers/template_manager'
require 'onapp_template'
require 'virtual_machine/disks'
require 'virtual_machine/vm_operations'
require 'yaml'

class VirtualMachine  
  include OnappHTTP
  include Hypervisor
  include Disks
  include VmOperationsWaiters  
  
  attr_reader :hypervisor_id, :template
  attr_reader :id, :identifier, :memory, :cpus, :cpu_share, :label, :hostname
  
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
  
    hash ={'virtual_machine' => {
      'hypervisor_id' => @hypervisor_id,
      'template_id' => @template.id,
      'label' => @template.file_name,
      'memory' => @template.min_memory_size,
      'cpus' => '1',
      'cpu_shares' => '1',
      'primary_disk_size' => @template.min_disk_size,
      'hostname' => 'autotest',
      'required_virtual_machine_build' => '1',
      'required_ip_address_assignment' => '1',
      }}
    hash['virtual_machine']['swap_disk_size'] = '1' if @template.allowed_swap
  
    
    result = post("#{@url}/virtual_machines", hash)
    result = result['virtual_machine']
    
    @id = result['id']
    @identifier = result['identifier']
    @label = result['label']
    @hostname = result['hostname']
    @memory = result['memory']
    @cpu = result['cpus']
    @cpu_shares = result['cpu_shares']
    
    @disks = get("#{@url}/virtual_machines/#{@identifier}/disks.json")
    
# Build VM process
    disk_wait_for_build('primary')
    disk_wait_for_build('swap') if @template.allowed_swap    
    disk_wait_for_provision('primary') if @template.operating_system != 'freebsd'
    disk_wait_for_provision('swap') if @template.operating_system == 'freebsd'
    wait_for_configure_operaiong_system
    wait_for_start
# Build VM process (END)    
  end
  
  def destroy
    delete("#{@url}/virtual_machines/#{@identifier}.json")
    wait_for_destroy
  end
end