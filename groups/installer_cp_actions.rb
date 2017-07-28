require './groups/virtual_server_actions'

class InstallerCpActions < VirtualServerActions
  def precondition
    @virtual_machine = InstallerCp.new(self)
    @settings = Settings.new(self)

    if IDENTIFIER
      @virtual_machine.find(IDENTIFIER)
    else
      @template = ImageTemplate.new(self)
      @template.find_by_manager_id(TEMPLATE_MANAGER_ID)

      @hypervisor = Hypervisor.new(self)
      @hypervisor.find_by_virt(VIRT_TYPE)

      @virtual_machine.create(label: 'auto_install_cp', memory: '4096', primary_disk_size: '15')
    end

    self
  end
end