require 'virtual_machine/vm_base'

require 'pry'

describe "VIRTUAL MACHINE REGRESSION AUTOTEST" do
  before :all do
    @vm = VirtualMachine.new
    @vm.create(ENV['TEMPLATE_MANAGER_ID'],ENV['VIRT_TYPE'])
    expect(@vm.is_created?).to be true
  end
  after :all do

  end  
  it 'Resize' do
    while true do
      @vm.stop
      @vm.wait_for_stop
      @vm.start_up
      @vm.wait_for_start
      @vm.reboot
      @vm.wait_for_reboot
    end
  end

    
end