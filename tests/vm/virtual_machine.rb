require 'virtual_machine/onapp_vm'

require 'pry'

describe "VIRTUAL MACHINE REGRESSION AUTOTEST" do
  before :all do    
    @vm = VirtualMachine.new('debian-7.0-x64-1.4-xen.kvm.kvm_virtio.tar.gz','kvm6')                 
  end
  after :all do
    @vm.destroy
  end
  
  describe "VM power operations" do    
    it "Stop/Start Virtual Machine" do
      @vm.stop
      @vm.start_up            
    end
    it "ShutDown/Start Virtual Machine" do
      @vm.shut_down
      @vm.start_up
    end    
    it "Reboot Virtual Machine" do
      @vm.reboot                  
    end
    it "Rebuild Virtual Machine" do
      @vm.rebuild
    end

  end
  describe "Edit VM operations" do
    it "empty test 1" do
      true
    end
  end  
    
end