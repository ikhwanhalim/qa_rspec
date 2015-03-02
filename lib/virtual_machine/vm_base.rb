require 'helpers/onapp_http'
require 'helpers/hypervisor'
require 'helpers/template_manager'
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
    auth unless self.conn
    if user
      auth url: @url, user: user.login, pass: user.password
    end
  end

  def create(manager_id, virtualization, federation={})
    Log.info("Template manager id is: #{manager_id || federation['template']['label']}")
    Log.info("Hypervisor virtualization is: #{virtualization || federation['hypervisor']['hypervisor_type']}")
    if federation.any?
      @template = federation['template']
      @hypervisor = federation['hypervisor']
    else
      @template = get_template(manager_id)
      @hypervisor = for_vm_creation(virtualization)
    end

    hash ={'virtual_machine' => {
                                  'hypervisor_id' => @hypervisor['id'],
                                  'template_id' => @template['id'],
                                  'label' => @template['label'],
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
    @virtual_machine = post("/virtual_machines", hash)['virtual_machine']
    @route = "/virtual_machines/#{@virtual_machine['identifier']}"

    3.times do
      @disks = get("#{@route}/disks")
      @network_interfaces = get("#{@route}/network_interfaces")
      @ip_addresses = get("#{@route}/ip_addresses")
      break if @disks.any? && @network_interfaces.any? && @ip_addresses.any?
      sleep 10
    end
    find_by_id
    return self
  end

  def is_created?
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
  def find_by_id(identifier=nil)
    identifier ||= @virtual_machine['identifier']
    @virtual_machine = get("/virtual_machines/#{identifier}")['virtual_machine']
    @route = "/virtual_machines/#{@virtual_machine['identifier']}"
    @disks = get("#{@route}/disks")
    @network_interfaces = get("#{@route}/network_interfaces")
    @ip_addresses = get("#{@route}/ip_addresses")
    @template = get("/templates/#{@virtual_machine['template_id']}")
    @virtual_machine
  end

  def edit_ram(action, value, expect_code='204')
    case action
      when 'incr'
        new_mem = @virtual_machine['memory'].to_i + value.to_i
      when 'decr'
        new_mem = @virtual_machine['memory'].to_i - value.to_i
      when 'set'
        new_mem = value.to_i
      else
        raise("Unknown action #{action}. Please use incr/decr/set actions")
    end
    hash = {'virtual_machine' => {'memory' => new_mem.to_s, 'allow_migration' => '0', 'allow_cold_resize' => '0'}}
    result = put("#{@route}", hash)
    puts result
    raise("Unexpected responce code. Expected = #{expect_code}, got = #{api_responce_code} ") if api_responce_code != expect_code
    wait_for_resize_without_reboot

  end
  def edit_cpu(value, action)

  end
  def edit_cpu_priority(value, param)

  end
# OPERATIONS
  def api_responce_code
    @conn.page.code
  end

  def destroy
    delete("#{@route}")
    api_responce_code == '201'    
  end

  def stop
    post("#{@route}/stop")
    api_responce_code == '201'
  end

  def shut_down
    post("#{@route}/shutdown")
    api_responce_code == '201'
  end

  def start_up
    post("#{@route}/startup")
    api_responce_code == '201'
  end

  def reboot(mode=nil)
    post("#{@route}/reboot")
    api_responce_code == '201'
  end

  def rebuild(template = @template)
    post("#{@route}/build", {'template_id' => template.id.to_s, 'required_startup' => '1'})
    disk_wait_for_format('primary')    
    disk_wait_for_format('swap') if @template['allowed_swap']
    disk_wait_for_provision('primary') if @template['operating_system'] != 'freebsd'
    disk_wait_for_provision('swap') if @template['operating_system'] == 'freebsd'
    wait_for_configure_operating_system
    wait_for_provision_win if @template['operating_system'] == 'windows'
    wait_for_start
  end

  def info_update
    @virtual_machine = get("#{@route}")['virtual_machine']
    @disks = get("#{@route}/disks")
    @network_interfaces = get("#{@route}/network_interfaces")
    @ip_addresses = get("#{@route}/ip_addresses")

  end

  def exist_on_hv?
    cred = { 'vm_host' => "#{@hypervisor['ip_address']}" }
    if @hypervisor['hypervisor_type'] == 'kvm'
      result = !tunnel_execute(cred, "virsh list | grep #{@virtual_machine['identifier']} || echo 'false'").first.include?('false')
    elsif @hypervisor['hypervisor_type'] == 'xen'
      result = !tunnel_execute(cred, "xm list | grep #{@virtual_machine['identifier']} || echo 'false'").first.include?('false')
    end
    return result
  end
end

