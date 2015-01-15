require 'virtual_machine/vm_base'

require 'pry'

describe "VIRTUAL MACHINE REGRESSION AUTOTEST" do
  before :all do    
    @vm = VirtualMachine.new('debian-7.0-x64-1.4-xen.kvm.kvm_virtio.tar.gz','kvm6')                 
  end
  after :all do
    @vm.destroy
  end  
  describe "Network" do
    it "wait" do
      @vm.ssh_port_opened.should be_true
      #binding.pry
    end
  end  
    
end