require 'onapp_supplier'
require 'onapp_trader'
require 'virtual_machine/vm_base'

describe "Federation Virtual Machine" do
  before :all do
    @supplier = OnappSupplier.new
    @trader = OnappTrader.new
    @supplier.add_to_federation
    federation_id = @supplier.published_zone['federation_id']
    @trader.wait_for_publishing(federation_id)
    @trader.subscribe(federation_id)
    @trader.create_vm(@supplier.template['label'], federation_id)
    @supplier.find_vm(federation_id)
    expect(@trader.vm.pinged?).to be true
  end

  after :all do
    @trader.vm.destroy
    @trader.vm.wait_for_destroy
    @trader.unsubscribe_all
    @supplier.remove_all_from_federation
  end

  let(:federation_id) { @trader.subscribed_zone['federation_id'] }

  it "should pinged after booting" do
    expect(@trader.vm.pinged? && @trader.vm.ssh_port_opened).to be true
  end

  it "should be created on supplier HV" do
    expect(@supplier.vm.exist_on_hv?).to be true
  end

  it "trader should be able reboot" do
    expect(@trader.vm.reboot).to be true
    @trader.vm.wait_for_reboot
    expect(@trader.vm.pinged? && @trader.vm.ssh_port_opened).to be true
  end

  it "supplier should be able reboot" do
    expect(@supplier.vm.reboot).to be true
    @supplier.vm.wait_for_reboot
    expect(@supplier.vm.pinged? && @supplier.vm.ssh_port_opened).to be true
  end

  describe 'Firewall rules' do
    before { @trader.vm.destroy_all_firewall_rules }

    describe "Default firewall rules" do
      it "should be ACCEPT" do
        rule = @trader.vm.network_interfaces.first['network_interface']['default_firewall_rule']
        expect(rule).to eq 'ACCEPT'
      end

      it "set default firewall rule" do
        skip('CORE-3955')
        @trader.vm.set_default_firewall_rule(command: 'DROP')
        @trader.vm.update_firewall_rules
        expect(@trader.vm.pinged?(attemps: 3)).to be false
        expect(@trader.vm.is_port_opened?(port: 22, time: 1)).to be false
        @trader.vm.set_default_firewall_rule(command: 'ACCEPT')
        @trader.vm.update_firewall_rules
        expect(@trader.vm.pinged?(attemps: 3)).to be true
        expect(@trader.vm.is_port_opened?(port: 22, time: 1)).to be true
      end
    end

    it "should be able create DROP rule to 22 port" do
      @trader.vm.create_firewall_rule(port: 22, command: 'DROP')
      @trader.vm.update_firewall_rules
      expect(@trader.vm.is_port_opened?(port: 22, time: 1)).to be false
    end

    it "create DROP rule for ICMP" do
      @trader.vm.create_firewall_rule(protocol: 'ICMP', command: 'DROP')
      @trader.vm.update_firewall_rules
      expect(@trader.vm.pinged?(attemps: 3)).to be false
    end

    it "should be able edit firewall rule" do
      @trader.vm.create_firewall_rule(port: 22, command: 'DROP')
      @trader.vm.update_firewall_rules
      expect(@trader.vm.is_port_opened?(port: 22, time: 1)).to be false
      id = @trader.vm.firewall_rules.first["firewall_rule"]["id"]
      @trader.vm.edit_firewall_rule(id, {command: 'ACCEPT'})
      @trader.vm.update_firewall_rules
      expect(@trader.vm.is_port_opened?(port: 22, time: 1)).to be true
    end

    it "should be able remove firewall rule" do
      @trader.vm.create_firewall_rule(port: 22, command: 'DROP')
      @trader.vm.update_firewall_rules
      id = @trader.vm.firewall_rules.first["firewall_rule"]["id"]
      @trader.vm.delete_firewall_rule(id)
      @trader.vm.update_firewall_rules
      expect(@trader.vm.firewall_rules.empty?).to be true
    end
  end

  describe "Normal backup" do

    it {}
  end

  describe "New IP address" do
    before :all do
      @ip_join = @trader.vm.allocate_new_ip
    end

    after :all do
      @trader.vm.delete_ip(@ip_join['id'])
    end

    it 'should pinged' do
      expect(@trader.vm.pinged?(ip_address_number: 1)).to be true
      expect(@trader.vm.pinged?(ip_address_number: 2)).to be true
    end

    it 'SSH port should be opened' do
      expect(@trader.vm.is_port_opened?(ip: @ip_join['ip_address']['address'])).to be true
      expect(@trader.vm.ssh_port_opened).to be true
    end
  end
end