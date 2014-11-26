require 'helpers/onapp_http'
require 'helpers/hypervisor'
require 'helpers/template_manager'
require 'onapp_template'
require 'virtual_machine/disks'
require 'virtual_machine/vm_operations_waiter'
require 'virtual_machine/networks'
require 'helpers/onapp_ssh'

require 'yaml'

class VirtualMachine  
  include OnappHTTP
  include OnappSSH
  include Hypervisor
  include Disks
  include VmOperationsWaiters
  include VmNetwork  
  
  attr_reader :hypervisor_id,
              :hypervisor,
              :template,
              :id,
              :identifier,
              :memory,
              :cpus,
              :cpu_shares,
              :label,
              :hostname,
              :price_per_hour,
              :price_per_hour_powered_off,
              :disks,
              :network_interfaces,
              :ip_addresses
  
  def initialize(template,virtualization,user=nil)
    data = YAML::load_file('config/conf.yml')
    @url = data['url']    
    @ip = data['ip']
    auth "#{@url}/users/sign_in", data['user'], data['pass']        
    @template = OnappTemplate.new template    
    @hypervisor = for_vm_creation(virtualization)
    @hypervisor_id = @hypervisor['id']    
    if !user.nil?
      @conn=nil      
      auth "#{@url}/users/sign_in", user.login, user.password
    end
    hash ={'virtual_machine' => {
      'hypervisor_id' => @hypervisor['id'],
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
    @cpus = result['cpus']
    @cpu_shares = result['cpu_shares']

    @price_per_hour = result['price_per_hour']
    @price_per_hour_powered_off = result['price_per_hour_powered_off']
    
    @disks = get("#{@url}/virtual_machines/#{@identifier}/disks.json")    
    @network_interfaces = get("#{@url}/virtual_machines/#{@identifier}/network_interfaces.json")    
    @ip_addresses = get("#{@url}/virtual_machines/#{@identifier}/ip_addresses.json")    
    
# Build VM process (BEGIN)
    disk_wait_for_build('primary')
    disk_wait_for_build('swap') if @template.allowed_swap    
    disk_wait_for_provision('primary') if @template.operating_system != 'freebsd'
    disk_wait_for_provision('swap') if @template.operating_system == 'freebsd'    
    wait_for_configure_operaiong_system
    wait_for_provision_freebsd if @template.operating_system == 'freebsd'
    wait_for_provision_win if @template.operating_system == 'windows'
    wait_for_start
# Build VM process (END)    
  end


  
# OPERATIONS
  def api_responce_code
    @conn.page.code
  end

  def destroy
    delete("#{@url}/virtual_machines/#{@identifier}.json")
    api_responce_code == '201'    
  end
  def stop
    post("#{@url}/virtual_machines/#{@identifier}/stop.json")
    api_responce_code == '201'
  end
  def shut_down
    post("#{@url}/virtual_machines/#{@identifier}/shutdown.json")
    api_responce_code == '201'
  end
  def start_up
    post("#{@url}/virtual_machines/#{@identifier}/startup.json")
    api_responce_code == '201'
  end
  def reboot(mode=nil)
    post("#{@url}/virtual_machines/#{@identifier}/reboot.json")
    api_responce_code == '201'
  end
  def rebuild(template = @template)
    post("#{@url}/virtual_machines/#{@identifier}/build.json", {'template_id' => template.id.to_s, 'required_startup' => '1'})
    disk_wait_for_format('primary')    
    disk_wait_for_format('swap') if @template.allowed_swap    
    disk_wait_for_provision('primary') if @template.operating_system != 'freebsd'
    disk_wait_for_provision('swap') if @template.operating_system == 'freebsd'    
    wait_for_configure_operaiong_system
    wait_for_provision_win if @template.operating_system == 'windows'
    wait_for_start
  end


  def info_update
    result = get("#{@url}/virtual_machines/#{@identifier}.json")
    result = result['virtual_machine']
    @id = result['id']
    @identifier = result['identifier']
    @label = result['label']
    @hostname = result['hostname']
    @memory = result['memory']
    @cpu = result['cpus']
    @cpu_shares = result['cpu_shares']

    @price_per_hour = result['price_per_hour']
    @price_per_hour_powered_off = result['price_per_hour_powered_off']

    @disks = get("#{@url}/virtual_machines/#{@identifier}/disks.json")
    @network_interfaces = get("#{@url}/virtual_machines/#{@identifier}/network_interfaces.json")
    @ip_addresses = get("#{@url}/virtual_machines/#{@identifier}/ip_addresses.json")
  end

  def exist_on_hv?
    cred = { 'vm_host' => "#{@hypervisor['ip_address']}" }
    result = !tunnel_execute(cred, "virsh list | grep #{@identifier} || echo 'false'").first.include?('false') if @hypervisor['hypervisor_type'] == 'kvm'
    result = !tunnel_execute(cred, "xm list | grep #{@identifier} || echo 'false'").first.include?('false') if @hypervisor['hypervisor_type'] == 'xen'
    return result
  end


end

