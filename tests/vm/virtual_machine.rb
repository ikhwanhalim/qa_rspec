require 'virtual_machine/onapp_vm'
require 'virtual_machine/onapp_vm_disk'
require 'pry'

describe "VIRTUAL MACHINE REGRESSION AUTOTEST" do
  before :all do    
    #TODO template manager should return template ID    
    #hypervisor_id =  
    #$virtual_machine = VirtualMachine.new(template, '')                 
  end
  after :all do
    
  end  
  
  describe 'Build VM' do
    it "Should be possible to buid VM" do
      #$vm= VirtualMachine.new('centos-6.0-x64-1.2.tar.gz','kvm6').create
      $disk = Disk.new
      binding.pry
    end
  end
    
end