require 'virtual_machine/vm_base'

describe "Virtual machine template: #{ENV['TEMPLATE_MANAGER_ID']}, virtualization: #{ENV['VIRT_TYPE']}" do
  before :all do
    @vm = VirtualMachine.new
    @vm.create(ENV['TEMPLATE_MANAGER_ID'],ENV['VIRT_TYPE'])
    expect(@vm.is_created?).to be true
  end

  before do
    expect(@vm.pinged?).to be true
  end

  after :all do
    @vm.destroy
    @vm.wait_for_destroy
  end

  it 'should be able via ssh' do
    expect(@vm.ssh_port_opened).to be true
  end

  it 'should be able after upgrade' do
    pending
  end

  it 'should be able after rebuild network' do
    pending
  end

  it 'should be able after reboot' do
    pending
  end
end