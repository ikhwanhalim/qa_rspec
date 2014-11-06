require 'onapp_template.rb'
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
      $template = OnappTemplate.new "centos-6.0-x64-1.2.tar.gz"
      binding.pry
    end
  end
    
end