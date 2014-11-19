require 'virtual_machine/onapp_vm'

require 'pry'

describe "VIRTUAL MACHINE REGRESSION AUTOTEST" do
  before :all do    
    @vm = VirtualMachine.new('debian-7.0-x64-1.4-xen.kvm.kvm_virtio.tar.gz','kvm6')                 
  end
  after :all do
    @vm.destroy
    @vm.wait_for_destroy
  end  
  describe "VM power operations" do    
    it "Stop/Start Virtual Machine" do
      @vm.ssh_port_opened.should be_truthy
      @vm.stop.should be_truthy      
      @vm.wait_for_stop.should be_truthy
      @vm.ssh_port_opened.should be_falsey      
      @vm.start_up.should be_truthy      
      @vm.wait_for_start.should be_truthy
      @vm.ssh_port_opened.should be_truthy            
    end
    it "ShutDown/Start Virtual Machine" do
      @vm.shut_down.should be_truthy      
      @vm.wait_for_stop.should be_truthy
      @vm.ssh_port_opened.should be_falsey  
      @vm.start_up.should be_truthy      
      @vm.wait_for_start.should be_truthy
      @vm.ssh_port_opened.should be_truthy
    end    
    it "Reboot Virtual Machine" do
      @vm.reboot.should be_truthy      
      @vm.wait_for_reboot
      @vm.ssh_port_opened.should be_truthy                  
    end
  end
  describe "Network operations" do
    it "Should be possible to do something" do
      true
    end
  end    
end