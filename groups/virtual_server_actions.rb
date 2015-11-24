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
require 'ip_address'
require 'disk'
require 'network_interface'
require 'iso'

require 'mechanize'
require 'socket'
require 'active_support/all'
require 'hashie'
require 'net/ssh'
require 'fog-onapp'
require 'fog/json'
require 'timeout'

class VirtualServerActions
  include FogOnapp, ApiClient, SshClient, TemplateManager, Log

  attr_accessor :hypervisor, :template
  attr_reader   :virtual_machine, :iso

  def precondition
    @iso = Iso.new(self)
    data = {'label' => 'iso_api_test',
            'make_public' => '0',
            'min_memory_size' => '256',
            'version' => '1.0',
            'operating_system' => 'Linux',
            'operating_system_distro' => 'Fedora',
            'virtualization' => ["xen", "kvm"],
            'file_url' => 'http://templates.repo.onapp.com/Linux-iso/Fedora-Server-netinst-x86_64-21.iso'}
    @iso.create(data)

    @template = ImageTemplate.new(self)
    @template.find_by_manager_id(ENV['TEMPLATE_MANAGER_ID'])

    @hypervisor = Hypervisor.new(self)
    @hypervisor.find_by_virt(ENV['VIRT_TYPE'])

    @virtual_machine = VirtualServer.new(self)
    @virtual_machine.create

    self
  end
end