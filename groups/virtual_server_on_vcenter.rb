class VirtualServerOnVCenter
  include ApiClient, Log, SshClient


  OVA_ID = '521'

  attr_accessor :vcenter, :template_obj

  alias template template_obj
  alias hypervisor vcenter

  def precondition(template_type='ova')

    @template_obj = Ova.new(self).find('577') if template_type == 'ova'
    @template_obj = ImageTemplate.new(self).find_by_id('601') if template_type == 'image'

    @vcenter = VCenter.new(self)
    @vcenter.find_by_virt

    @virtual_machine=VirtualServer.new(self)
    @virtual_machine.create()

    # Log.error('VS is not available. No ping available') if !@virtual_machine.pinged?
    # Log.error('VS is not available. Ssh port closed') if !@virtual_machine.port_opened?
    self
  end

  # @return VirtualServer
  def virtual_machine
    @virtual_machine
  end

  def aftercondition
    @virtual_machine.info_update
    @virtual_machine.unlock if @virtual_machine.locked
    @virtual_machine.shut_down if @virtual_machine.booted
    @virtual_machine.destroy
  end
  def update_info

  end
end
