require 'helpers/onapp_http'
require 'helpers/hypervisor'
require 'helpers/template_manager'
require 'virtual_machine/vm_disks'
require 'virtual_machine/vm_operations_waiter'
require 'virtual_machine/vm_networks'
require 'helpers/onapp_ssh'
require 'helpers/template_manager'
require 'virtual_machine/vm_firewall'

require 'yaml'

class VirtualMachine  
  include OnappHTTP, OnappSSH, Hypervisor, TemplateManager, VmDisks, VmOperationsWaiters, VmNetwork, VmFirewall

  attr_accessor :virtual_machine

  def initialize(user=nil, federation: nil)
    if federation
      auth(url: federation['url'], user: federation['user'], pass: federation['pass'])
    elsif user
      auth(url: @url, user: user.login, pass: user.password)
    elsif !self.conn
      auth unless self.conn
    end
  end

  def create(manager_id, virtualization, federation={})
    Log.info("Template manager id is: #{manager_id || federation['template']['label']}")
    Log.info("Hypervisor virtualization is: #{virtualization || federation['hypervisor']['hypervisor_type']}")
    if federation.any?
      @template = federation['template']
      @hypervisor = federation['hypervisor']
      @label = federation['hypervisor']['label']
    else
      @template = get_template(manager_id)
      @hypervisor = for_vm_creation(virtualization)
    end

    hash ={'virtual_machine' => {
                                  'hypervisor_id' => @hypervisor['id'],
                                  'template_id' => @template['id'],
                                  'label' => @label || @template['label'],
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
    @virtual_machine = post("/virtual_machines", hash)
    if @virtual_machine.has_key?("errors")
      return @virtual_machine['errors']
    else
      @virtual_machine = @virtual_machine['virtual_machine']
      3.times do
        info_update
        break if @disks.any? && @network_interfaces.any? && @ip_addresses.any?
        sleep 10
      end
      find_by_id(identifier)
      return self
    end
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
  def find_by_id(identifier)
    @virtual_machine = get("/virtual_machines/#{identifier}")['virtual_machine']
    info_update
  end

  def find_by_label(label)
    get("/virtual_machines").each do |vm|
      if vm['virtual_machine']['label'] == label
        @virtual_machine = vm['virtual_machine']
        break
      end
    end
    self
  end
  def update_last_transaction
    @last_transaction_id = get('/transactions', {page: 1, per_page: 10}).first['transaction']['id']
  end

# Edit VM sections
  def resize_support?
    @template['resize_without_reboot_policy'].empty?
  end
  def edit(resource, action, value, expect_code='204')
    Log.error ("Unknown resize_without_reboot_policy for template: #{@template['manager_id']}") if resize_support?
    new = new_resource_value(resource,action,value)
    hash = {'virtual_machine' => {resource => new.to_s, 'allow_migration' => '0', 'allow_cold_resize' => '1'}}
    result = put("#{@route}", hash)
    puts result
    Log.error ("Unexpected responce code. Expected = #{expect_code}, got = #{api_responce_code} \n #{result}") if api_responce_code != expect_code
    old = @virtual_machine[resource]
    @virtual_machine[resource] = new
    if hot_resize_available?(resource, new, old)
      wait_for_resize_without_reboot
    else
      wait_for_resize
    end
  end
# Resources compare
  def cpu_shares_correct?
    to_compare = cpu_shares_on_hv
    Log.info ("Comparing CPU shares: On HV: #{to_compare}, on CP: #{cpu_shares}")
    to_compare = 1 if to_compare.to_i == 2 && cpu_shares.to_i == 1
    Log.info ("Comparing CPU shares: On HV: #{to_compare}, on CP: #{cpu_shares}")
    Log.error("Comparing CPU shares: On HV: #{to_compare}, on CP: #{cpu_shares}") if to_compare.to_i != cpu_shares.to_i
    true
  end
  def cpus_correct?
    to_compare = cpus_on_vm
    Log.info ("Comparing CPUs: On VM: #{to_compare}, on CP: #{cpus}")
    Log.error("Comparing CPUs: On VM: #{to_compare}, on CP: #{cpus} FAILED") if to_compare.to_i != cpus.to_i
    true
  end
  def memory_correct?
    to_compare = memory_on_vm
    Log.info ("Comparing Memory: On VM: #{to_compare}, on CP: #{memory}")
    Log.error ("Comparing Memory: On VM: #{to_compare}, on CP: #{memory} FAILED") if to_compare.to_f/memory.to_i < 0.7
    true
  end

# Migrations
  def hv_to_migrate_exist?
    !hv_for_vm_migration.nil?
  end
  def hot_migrate(expect_code='201')
    new_hv = hv_for_vm_migration
    hash = {'virtual_machine' => {'destination' => new_hv['id'], 'cold_migrate_on_rollback' => '0'}}
    result = post("#{@route}/migrate", hash)
    Log.error ("Unexpected responce code. Expected = #{expect_code}, got = #{api_responce_code} \n #{result}") if api_responce_code != expect_code
    wait_for_hot_migration
    @hypervisor = new_hv
    @virtual_machine['hypervisor_id'] = @hypervisor['id']
  end
  def cold_migrate(expect_code='201')
    shut_down
    wait_for_stop

    new_hv = hv_for_vm_migration
    hash = {'virtual_machine' => {'destination' => new_hv['id']}}
    post("#{@route}/migrate", hash)
    Log.error ("Unexpected responce code. Expected = #{expect_code}, got = #{api_responce_code} \n #{result}") if api_responce_code != expect_code
    wait_for_cold_migration
    @hypervisor = new_hv
    @virtual_machine['hypervisor_id'] = @hypervisor['id']

    start_up
    wait_for_start
  end

# Recovery
  def recovery_reboot
    post("#{@route}/reboot",'','?mode=recovery')
    api_responce_code == '201'
  end
  def recovery?
    check_hostname.include?('recovery')
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

  def reboot
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
    @route ||= "/virtual_machines/#{@virtual_machine['identifier']}"
    @virtual_machine = get("#{@route}")['virtual_machine']
    @disks = get("#{@route}/disks")
    @network_interfaces = get("#{@route}/network_interfaces")
    @ip_addresses = get("#{@route}/ip_addresses")
    @template = get("/templates/#{@virtual_machine['template_id']}")['image_template']
    @hypervisor = get("/hypervisors/#{@virtual_machine['hypervisor_id']}")['hypervisor']
  end

  def exist_on_hv?
    cred = { 'vm_host' => "#{@hypervisor['ip_address']}" }
    if @hypervisor['hypervisor_type'] == 'kvm'
      result = tunnel_execute(cred, "virsh list | grep #{identifier} || echo 'false'").first.exclude?('false')
    elsif @hypervisor['hypervisor_type'] == 'xen'
      result = tunnel_execute(cred, "xm list | grep #{identifier} || echo 'false'").first.exclude?('false')
    end
    return result
  end

  # VM params
  ######################################################################################################################
  def identifier
    @virtual_machine['identifier']
  end

  def cpus
    @virtual_machine['cpus']
  end

  def cpu_shares
    @virtual_machine['cpu_shares']
  end

  def memory
    @virtual_machine['memory']
  end

  def disks
    @disks
  end

  def ip_addresses
    @ip_addresses
  end

  def network_interfaces
    @network_interfaces
  end
  def hypervisor
    @hypervisor
  end

  def price_per_hour
    @virtual_machine['price_per_hour']
  end

  def price_per_hour_powered_off
    @virtual_machine['price_per_hour_powered_off']
  end
  ######################################################################################################################
  # Private Methods
  private
  def new_resource_value(resource, action, value)
    case action
      when 'incr'
        new_value= @virtual_machine[resource].to_i + value.to_i
      when 'decr'
        new_value = @virtual_machine[resource].to_i - value.to_i
      when 'set'
        new_value = value.to_i
      else
        raise("Unknown action #{action}. Please use incr/decr/set actions")
    end
    new_value
  end

  def hot_resize_available?(resource, new_value, old_value)
    policy = @template['resize_without_reboot_policy']["#{@hypervisor['hypervisor_type']}"]["#{@hypervisor['distro']}"]
    if resource == 'cpus'
      if new_value > old_value and [1, 3, 5, 7, 9, 11, 13, 15].include? policy
        return true
      elsif new_value < old_value and [2, 3, 6, 7, 10, 11, 14, 15].include? policy
        return true
      else
        return false
      end
    elsif resource == 'memory'
      if new_value > old_value and new_value <= @maxmem and  [4, 5, 6, 7, 12, 13, 14, 15].include? policy
        return true
      elsif new_value < old_value and new_value <= @maxmem and [8, 9, 10, 11, 12, 13, 14, 15].include? policy
        return true
      else
        return false
      end
    elsif resource == 'cpu_shares'
      return true
    else
      Log.error("Unknown Resource #{resource}, Expected cpus, memory or cpu_shares")
    end
  end
end

