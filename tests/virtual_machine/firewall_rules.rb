require 'virtual_machine/vm_base'

describe 'VIRTUAL MACHINE REGRESSION AUTOTEST' do

  before :all do
    @vm = VirtualMachine.new
    @vm.create(ENV['TEMPLATE_MANAGER_ID'],ENV['VIRT_TYPE'])
    expect(@vm.is_created?).to be true
    expect(@vm.pinged?).to be true
  end

  before { @vm.destroy_all_firewall_rules }

  after :all do
    @vm.destroy
    @vm.wait_for_destroy
  end

  describe "Firewall rules" do

    describe "Default firewall rules" do
      it "set default firewall rule" do
        @vm.set_default_firewall_rule(command: 'DROP')
        @vm.update_firewall_rules
        expect(@vm.pinged?(attemps: 3)).to be false
        expect(@vm.is_port_opened?(port: 22, time: 1)).to be false
        @vm.set_default_firewall_rule(command: 'ACCEPT')
        @vm.update_firewall_rules
        expect(@vm.pinged?(attemps: 3)).to be true
        expect(@vm.is_port_opened?(port: 22, time: 1)).to be true
      end
    end

    it "should be able create DROP rule to 22 port" do
      @vm.create_firewall_rule(port: 22, command: 'DROP')
      @vm.update_firewall_rules
      expect(@vm.is_port_opened?(port: 22, time: 1)).to be false
    end

    it "create DROP rule for ICMP" do
      @vm.create_firewall_rule(protocol: 'ICMP', command: 'DROP')
      @vm.update_firewall_rules
      expect(@vm.pinged?(attemps: 3)).to be false
    end

    it "should be able edit firewall rule" do
      rule = @vm.create_firewall_rule(port: 22, command: 'DROP')
      id = rule["firewall_rule"]["id"]
      @vm.update_firewall_rules
      expect(@vm.is_port_opened?(port: 22, time: 1)).to be false
      @vm.edit_firewall_rule(id, {command: 'ACCEPT'})
      @vm.update_firewall_rules
      expect(@vm.is_port_opened?(port: 22, time: 1)).to be true
    end

    it "should be able remove firewall rule" do
      rule = @vm.create_firewall_rule(port: 22, command: 'DROP')
      id = rule["firewall_rule"]["id"]
      @vm.update_firewall_rules
      @vm.delete_firewall_rule(id)
      @vm.update_firewall_rules
      expect(@vm.firewall_rules.empty?).to be true
    end
  end

end