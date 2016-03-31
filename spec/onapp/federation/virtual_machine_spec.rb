require 'spec_helper'

describe "Federation Virtual Machine" do
  before :all do
    @federation = Federation.new
    @federation.supplier.add_to_federation
    federation_id = @federation.supplier.published_zone.federation_id
    @federation.market.set_preflight
    @federation.trader.zone_appeared?(federation_id)
    @federation.trader.subscribe(federation_id)
    @federation.trader.create_vm(@federation.supplier.template.label)
  end

  after :all do
    @federation.trader.vm.destroy if @federation.trader.vm
    @federation.trader.unsubscribe_all
    @federation.supplier.remove_from_federation
  end

  let(:federation_id) { @trader.subscribed_zone.federation_id }
  let(:supplier) { @federation.supplier }
  let(:trader) { @federation.trader }
  let(:market) { @federation.market }

  it "should pinged after booting" do
    expect(trader.vm.up?).to be true
  end

  it "should be created on supplier HV" do
    expect(supplier.vm.exist_on_hv?).to be true
  end

  it "seller and buyer passwords should be different" do
     expect(trader.vm.initial_root_password).not_to eq supplier.vm.initial_root_password
  end

  describe 'Supplier should be able' do
    it "supplier should be able reboot" do
      expect(supplier.vm.reboot).to be true
      expect(supplier.vm.up?).to be true
    end
  end

  describe 'Trader should be able' do
    it "trader should be able reboot" do
      expect(trader.vm.reboot).to be true
      expect(trader.vm.pinged? && trader.vm.port_opened?).to be true
    end

    it "trader should be able rebuild vm", skip: 'CORE-6665' do
      skip('CORE-5530') if supplier.version == 4.2 || trader.version == 4.2
      trader.vm.rebuild
      expect(trader.vm.ssh_execute('hostname').join(' ')).to match trader.vm.hostname
    end

    it 'reset root password' do
      skip('Will work in 4.2') if supplier.version < 4.2 || trader.version < 4.2
      old_password = trader.vm.initial_root_password
      trader.vm.reset_root_password
      expect(trader.vm.initial_root_password).not_to eq old_password
      expect(trader.vm.port_opened?).to be true
      expect(trader.vm.ssh_execute('hostname').join(' ')).to match trader.vm.hostname
    end

    it 'rebuild network' do
      expect(trader.vm.rebuild_network).to be true
      expect(trader.vm.up?).to be true
    end

    describe 'Perform disk action' do
      before :all do
        @disk = @federation.trader.vm.add_disk
        @federation.supplier.vm.disks(label: @disk.label).first.wait_for_build
      end

      let(:suppliers_disk) { @federation.supplier.vm.disks(label: @disk.label).first }
      let(:traders_disk) { @federation.trader.vm.disks(label: @disk.label).first }

      it 'add disk' do
        expect(trader.vm.port_opened?).to be true
        expect(trader.vm.disk_mounted?(suppliers_disk)).to be true
      end

      it 'edit disk' do
        traders_disk.edit(disk_size: 2, add_to_linux_fstab: true)
        expect(trader.vm.port_opened?).to be true
        trader.vm.info_update
        expect(trader.vm.total_disk_size).to eq 8
      end

      it 'remove disk' do
        traders_disk.remove
        expect(trader.vm.disks.count).to eq 2
      end
    end

    describe 'Firewall rules' do
      it 'set default firewall rule' do
        trader.vm.network_interface.set_default_firewall_rule('DROP')
        trader.vm.wait_for_receive_notification_from_market
        trader.vm.update_firewall_rules
        expect(trader.vm.not_pinged?).to be true
        trader.vm.network_interface.set_default_firewall_rule
        trader.vm.wait_for_receive_notification_from_market
        trader.vm.update_firewall_rules
        expect(trader.vm.pinged?).to be true
      end

      it 'add custom firewall rule' do
        trader.vm.network_interface.add_custom_firewall_rule(command: 'DROP', protocol: 'ICMP')
        trader.vm.wait_for_receive_notification_from_market
        trader.vm.update_firewall_rules
        expect(trader.vm.not_pinged?).to be true
        trader.vm.network_interface.reset_firewall_rules
        trader.vm.wait_for_receive_notification_from_market
        trader.vm.update_firewall_rules
        expect(trader.vm.pinged?).to be true
      end
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
      expect(!!supplier.vm.network_interface.add_custom_firewall_rule).to be false
    end

    it "rebuild network" do
      expect(supplier.vm.rebuild_network).to be false
    end

    it "add disk" do
      expect(!!supplier.vm.add_disk).to be false
    end

    it "destroy swap disk" do
      expect(!!supplier.vm.disk('swap').remove).to be false
    end

    it "allocate IP address" do
      expect(!!supplier.vm.network_interface.allocate_new_ip).to be false
    end

    it "remove IP address" do
      expect(!!supplier.vm.network_interface.remove_ip).to be false
    end

    it "connect via SSH with own ssh keys" do
      expect(supplier.vm.ssh_execute('hostname').join(' ')).to_not match supplier.vm.hostname
    end
  end
end