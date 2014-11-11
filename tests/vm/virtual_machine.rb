require 'virtual_machine/onapp_vm'

require 'pry'

describe "VIRTUAL MACHINE REGRESSION AUTOTEST" do
  before :all do    
                     
  end
  after :all do
    
  end    
  it "Should be possible to buid VM" do
    vm = VirtualMachine.new('centos-6.0-x64-1.2.tar.gz','kvm6')
    vm.destroy
  end  
    
end