require 'virtual_machine/vm_base'

require 'pry'

describe "VIRTUAL MACHINE REGRESSION AUTOTEST" do
  before :all do
    @vm = VirtualMachine.new
    @vm.create(ENV['TEMPLATE_MANAGER_ID'],ENV['VIRT_TYPE'])
    expect(@vm.is_created?).to be true
    expect(@vm.pinged?).to be true
  end
  after :all do
    @vm.destroy
    @vm.wait_for_destroy
  end

  describe "VM power operations" do
    it "Stop/Start Virtual Machine" do
      @vm.ssh_port_opened.should be_truthy
      @vm.exist_on_hv?.should be_truthy

      @vm.stop.should be_truthy      
      @vm.wait_for_stop.should be_truthy
      @vm.exist_on_hv?.should be_falsey

      @vm.start_up.should be_truthy      
      @vm.wait_for_start.should be_truthy
      @vm.exist_on_hv?.should be_truthy
      @vm.ssh_port_opened.should be_truthy            
    end
    it "ShutDown/Start Virtual Machine" do
      @vm.ssh_port_opened.should be_truthy
      @vm.exist_on_hv?.should be_truthy

      @vm.shut_down.should be_truthy      
      @vm.wait_for_stop.should be_truthy
      @vm.exist_on_hv?.should be_falsey


      @vm.start_up.should be_truthy      
      @vm.wait_for_start.should be_truthy
      @vm.exist_on_hv?.should be_truthy
      @vm.ssh_port_opened.should be_truthy
    end    
    it "Reboot Virtual Machine" do
      @vm.reboot.should be_truthy      
      @vm.wait_for_reboot
      @vm.exist_on_hv?.should be_truthy
      @vm.ssh_port_opened.should be_truthy
      @vm.template.virtualization
    end
  end

  describe "VM disks operations" do
    it "Should be possible edit primary disk" do
      @vm.edit_disk
      require 'pry';binding.pry
    end
  end

  describe "Network operations" do
    it "Should be possible to do something" do
      true
    end
  end    
end