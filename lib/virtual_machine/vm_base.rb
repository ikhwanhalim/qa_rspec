require 'helpers/onapp_http'
require 'helpers/hypervisor'
require 'helpers/template_manager'
require 'onapp_template'
require 'virtual_machine/vm_disks'
require 'virtual_machine/vm_operations_waiter'
require 'virtual_machine/vm_networks'
require 'helpers/onapp_ssh'
require 'helpers/template_manager'

require 'yaml'

class VirtualMachine  
  include OnappHTTP
  include OnappSSH
  include Hypervisor
  include TemplateManager
  include VmDisks
  include VmOperationsWaiters
  include VmNetwork  

  def initialize(user=nil)
    data = YAML::load_file('config/conf.yml')
    @url = data['url']    
    @ip = data['ip']
    auth "#{@url}/users/sign_in", data['user'], data['pass']
    if user
      @conn=nil      
      auth "#{@url}/users/sign_in", user.login, user.password
    end
  end

  def create(manager_id, virtualization)
    @template = get_template(manager_id)

    @hypervisor = for_vm_creation(virtualization)
    hash ={'virtual_machine' => {
                                  'hypervisor_id' => @hypervisor['id'],
                                  'template_id' => @template['id'],
                                  'label' => @template['file_name'],
                                  'memory' => @template['min_memory_size'],
                                  'cpus' => '1',
                                  'cpu_shares' => '1',
                                  'primary_disk_size' => @template['min_disk_size'],
                                  'hostname' => 'auto.test',
                                  'required_virtual_machine_build' => '1',
                                  'required_ip_address_assignment' => '1',
                                }
          }

    hash['virtual_machine']['swap_disk_size'] = '1' if @template['allowed_swap']

    @virtual_machine = post("#{@url}/virtual_machines", hash)['virtual_machine']

    @route = "#{@url}/virtual_machines/#{@virtual_machine['identifier']}"

    @disks = get("#{@route}/disks.json")
    @network_interfaces = get("#{@route}/network_interfaces.json")
    @ip_addresses = get("#{@route}/ip_addresses.json")

# Build VM process (BEGIN)

    disk_wait_for_build('primary')
    disk_wait_for_build('swap') if @template['allowed_swap']
    disk_wait_for_provision('primary') if @template['operating_system'] != 'freebsd'
    disk_wait_for_provision('swap') if @template['operating_system'] == 'freebsd'
    wait_for_configure_operating_system
    wait_for_provision_freebsd if @template['operating_system'] == 'freebsd'
    wait_for_provision_win if @template['operating_system'] == 'windows'
    wait_for_start
# Build VM process (END)
  end

# Get an existing VM
  def find_by_id(identifier)
    @virtual_machine = get("#{@url}/virtual_machines/#{identifier}.json")['virtual_machine']
    @route = "#{@url}/virtual_machines/#{@virtual_machine['identifier']}"
    @disks = get("#{@route}/disks.json")
    @network_interfaces = get("#{@route}/network_interfaces.json")
    @ip_addresses = get("#{@route}/ip_addresses.json")
  end

  def edit(**params)
    put("#{@route}.json", {'virtual_machine'=>params})
    info_update
  end
# OPERATIONS
  def api_responce_code
    @conn.page.code
  end

  def destroy
    delete("#{@route}.json")
    api_responce_code == '201'    
  end

  def stop
    post("#{@route}/stop.json")
    api_responce_code == '201'
  end

  def shut_down
    post("#{@route}/shutdown.json")
    api_responce_code == '201'
  end

  def start_up
    post("#{@route}/startup.json")
    api_responce_code == '201'
  end

  def reboot(mode=nil)
    post("#{@route}/reboot.json")
    api_responce_code == '201'
  end

  def rebuild(template = @template)
    post("#{@route}/build.json", {'template_id' => template.id.to_s, 'required_startup' => '1'})
    disk_wait_for_format('primary')    
    disk_wait_for_format('swap') if @template['allowed_swap']
    disk_wait_for_provision('primary') if @template['operating_system'] != 'freebsd'
    disk_wait_for_provision('swap') if @template['operating_system'] == 'freebsd'
    wait_for_configure_operating_system
    wait_for_provision_win if @template['operating_system'] == 'windows'
    wait_for_start
  end

  def info_update
    @virtual_machine = get("#{@route}.json")['virtual_machine']
    @disks = get("#{@route}/disks.json")
    @network_interfaces = get("#{@route}/network_interfaces.json")
    @ip_addresses = get("#{@route}/ip_addresses.json")

  end

  def exist_on_hv?
    cred = { 'vm_host' => "#{@hypervisor['ip_address']}" }
    result = !tunnel_execute(cred, "virsh list | grep #{@virtual_machine['identifier']} || echo 'false'").first.include?('false') if @hypervisor['hypervisor_type'] == 'kvm'
    result = !tunnel_execute(cred, "xm list | grep #{@virtual_machine['identifier']} || echo 'false'").first.include?('false') if @hypervisor['hypervisor_type'] == 'xen'
    return result
  end


end

