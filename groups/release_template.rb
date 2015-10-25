require 'helpers/api_client'
require 'helpers/ssh_client'
require 'helpers/logger'
require 'helpers/template_manager'
require 'helpers/transaction'

require 'template'
require 'hypervisor'
require 'virtual_server'
require 'backup_server'

class ReleaseTemplate
  include ApiClient, Transaction, SshClient, TemplateManager, Log

  attr_reader :vm, :bs, :hypervisor, :template

  def initialize
    auth unless self.conn
  end

  def precondition
    @template = Template.new(self)
    @template.find_by_manager_id(ENV['TEMPLATE_MANAGER_ID'])
    @bs = BackupServer.new(self)
    @bs.find_first_active
    @hypervisor = Hypervisor.new(self)
    @hypervisor.find_by_virt(ENV['VIRT_TYPE'])
    @vm = VirtualServer.new(self)
    @vm.create
    @vm.wait_for_build
    @vm.info_update
    self
  end
end