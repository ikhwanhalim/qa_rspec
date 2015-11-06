require 'helpers/api_client'
require 'helpers/ssh_client'
require 'helpers/logger'
require 'helpers/template_manager'
require 'helpers/transaction'
require 'helpers/fog_onapp'
require 'helpers/vm_operations_waiter'
require 'helpers/ssh_commands'
require 'helpers/waiter'
require 'helpers/network'
require 'helpers/disks_operations_waiters'

require 'image_template'
require 'hypervisor'
require 'virtual_server'
require 'backup_server'
require 'ip_address'
require 'disk'
require 'network_interface'

require 'mechanize'
require 'socket'
require 'active_support/all'
require 'hashie'
require 'net/ssh'
require 'fog-onapp'
require 'fog/json'
require 'timeout'

class ReleaseTemplate
  include FogOnapp, ApiClient, SshClient, TemplateManager, Log

  attr_accessor :hypervisor
  attr_reader   :virtual_machine, :backup_server, :template

  def initialize
    auth unless self.conn
  end

  def precondition
    @template = ImageTemplate.new(self)
    @template.find_by_manager_id(ENV['TEMPLATE_MANAGER_ID'])

    @backup_server = BackupServer.new(self)
    @backup_server.find_first_active

    @hypervisor = Hypervisor.new(self)
    @hypervisor.find_by_virt(ENV['VIRT_TYPE'])

    @virtual_machine = VirtualServer.new(self)
    @virtual_machine.create

    self
  end
end