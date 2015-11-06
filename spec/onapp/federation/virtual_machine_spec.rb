require 'federation'
require 'virtual_machine/vm_base'

describe "Federation Virtual Machine" do
  before :all do
    @federation = Federation.new
    @federation.supplier.add_to_federation
    federation_id = @federation.supplier.published_zone.federation_id
    @federation.market.set_preflight
    @federation.trader.zone_appeared?(federation_id)
    @federation.trader.subscribe(federation_id)
    @federation.trader.create_vm(@federation.supplier.template.label, federation_id)
    @federation.supplier.find_vm(federation_id)
  end

  after :all do
    @federation.trader.vm.destroy
    @federation.trader.vm.wait_for_destroy
    @federation.trader.unsubscribe_all
    @federation.supplier.remove_from_federation
  end

  let(:federation_id) { trader.subscribed_zone.federation_id }
  let(:supplier) { @federation.supplier }
  let(:trader) { @federation.trader }
  let(:market) { @federation.market }

  it "should pinged after booting" do
    expect(trader.vm.pinged? && trader.vm.ssh_port_opened).to be true
  end

  it "should be created on supplier HV" do
    expect(supplier.vm.exist_on_hv?).to be true
  end

  describe 'Supplier should be able' do
    it "supplier should be able reboot" do
      expect(supplier.vm.reboot).to be true
      supplier.vm.wait_for_reboot
      expect(supplier.vm.pinged? && supplier.vm.ssh_port_opened).to be true
    end
  end

  describe 'Trader should be able' do
    it "trader should be able reboot" do
      expect(trader.vm.reboot).to be true
      trader.vm.wait_for_reboot
      expect(trader.vm.pinged? && trader.vm.ssh_port_opened).to be true
    end

    it "trader should be able rebuild vm" do
      expect(trader.vm.rebuild(federated: true)).to be true
      expect(trader.vm.execute_with_pass('hostname').first).to eq trader.vm_hash.hostname
    end

    it 'reset root password' do
      old_password = trader.vm_hash.initial_root_password
      trader.vm.reset_root_password
      expect(trader.vm_hash.initial_root_password).not_to eq old_password
      expect(trader.vm.execute_with_pass('hostname').first).to eq trader.vm_hash.hostname
    end
  end

  describe 'Supplier should not be able' do
    it 'reset root password' do
      expect(supplier.vm.reset_root_password).to be false
    end

    it "rebuild vm" do
      expect(supplier.vm.rebuild).to be false
    end

    it "delete vm" do
      expect(supplier.vm.destroy).to be false
    end

    it "add firewall rule" do
      expect(supplier.vm.create_firewall_rule).to be false
    end

    it "rebuild network" do
      expect(supplier.vm.rebuild_network).to be false
    end

    it "add disk" do
      begin
        supplier.vm.add_disk
      rescue
        expect(supplier.vm.api_response_code ).to eq '404'
      end
    end

    it "destroy swap disk" do
      id = supplier.vm.disks.detect {|d| d.disk.id if d.disk.is_swap}
      begin
        supplier.vm.destroy_disk(id)
      rescue
        expect(supplier.vm.api_response_code ).to eq '404'
      end
    end

    it "allocate IP address" do
      expect(supplier.vm.allocate_new_ip).to be false
    end
  end

  describe 'Firewall rules' do
    before { @federation.trader.vm.destroy_all_firewall_rules }

    describe "Default firewall rules" do
      it "should be ACCEPT" do
        expect(@federation.trader.vm.network_interfaces.first.network_interface.default_firewall_rule).to eq 'ACCEPT'
      end

      it "set default firewall rule" do
        trader.vm.set_default_firewall_rule(command: 'DROP')
        expect(trader.vm.pinged?(attemps: 3)).to be false
        expect(trader.vm.is_port_opened?(port: 22, time: 1)).to be false
        trader.vm.set_default_firewall_rule(command: 'ACCEPT')
        expect(trader.vm.pinged?(attemps: 3)).to be true
        expect(trader.vm.is_port_opened?(port: 22, time: 1)).to be true
      end
    end

    it "should be able create DROP rule to 22 port" do
      trader.vm.create_firewall_rule(port: 22, command: 'DROP')
      trader.vm.update_firewall_rules
      expect(trader.vm.is_port_opened?(port: 22, time: 1)).to be false
    end

    it "create DROP rule for ICMP" do
      trader.vm.create_firewall_rule(protocol: 'ICMP', command: 'DROP')
      trader.vm.update_firewall_rules
      expect(trader.vm.pinged?(attemps: 3)).to be false
    end

    it "should be able edit firewall rule" do
      trader.vm.create_firewall_rule(port: 22, command: 'DROP')
      trader.vm.update_firewall_rules
      expect(trader.vm.is_port_opened?(port: 22, time: 1)).to be false
      id = trader.vm.firewall_rules.first.firewall_rule.id
      trader.vm.edit_firewall_rule(id, {command: 'ACCEPT'})
      trader.vm.update_firewall_rules
      expect(trader.vm.is_port_opened?(port: 22, time: 1)).to be true
    end

    it "should be able remove firewall rule" do
      trader.vm.create_firewall_rule(port: 22, command: 'DROP')
      trader.vm.update_firewall_rules
      id = trader.vm.firewall_rules.first.firewall_rule.id
      trader.vm.delete_firewall_rule(id)
      trader.vm.update_firewall_rules
      expect(trader.vm.firewall_rules.empty?).to be true
    end
  end

  describe "Normal backup" do
    it { skip }
  end

  describe "New IP address" do
    before :all do
      @ip_join = @federation.trader.vm.allocate_new_ip
    end

    after :all do
      @federation.trader.vm.delete_ip(@ip_join.id)
    end

    it 'should pinged' do
      expect(trader.vm.pinged?(ip_address_number: 1)).to be true
      expect(trader.vm.pinged?(ip_address_number: 2)).to be true
    end

    it 'SSH port should be opened' do
      expect(trader.vm.is_port_opened?(ip: @ip_join.ip_address.address)).to be true
      expect(trader.vm.ssh_port_opened).to be true
    end
  end
end