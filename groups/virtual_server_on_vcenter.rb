class VirtualServerOnVCenter
  include ApiClient, Log, SshClient

  attr_accessor :vcenter, :template_obj
  attr_reader :virtual_machine

  alias template template_obj
  alias hypervisor vcenter

  def precondition(template_type='ova')
    @template_obj = Ova.new(self).find('577') if template_type == 'ova'
    @template_obj = ImageTemplate.new(self).find_by_id('601') if template_type == 'image'
    @vcenter = VCenter.new(self)
    @vcenter.find_by_virt
    @virtual_machine=VirtualServer.new(self)
    @virtual_machine.create()
    self
  end

  def aftercondition
    @virtual_machine.info_update
    @virtual_machine.unlock if @virtual_machine.locked
    @virtual_machine.shut_down if @virtual_machine.booted
    @virtual_machine.destroy
  end
end
