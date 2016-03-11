require 'spec_helper'
require './groups/virtual_server_actions'

describe 'Windows Virtual Server actions tests' do
  before :all do
    @vsa = VirtualServerActions.new.precondition
    @vm = @vsa.virtual_machine
  end

  after :all do
    @vm.destroy
  end

  let(:vm) { @vsa.virtual_machine }

  let(:version) { @vsa.version }

  it 'VM should be created' do
    expect(vm.exist_on_hv?).to be true
  end

  it 'VM should exist on HV' do
    expect(vm.port_opened?).to be true
  end

  it 'Start/Stop' do
    vm.stop
    expect(vm.port_closed?).to be true
    vm.start_up
    expect(vm.port_opened?).to be true
  end

  it 'Reboot' do
    vm.reboot
    expect(vm.port_opened?).to be true
  end

  it 'Rebuild' do
    vm.rebuild
    expect(vm.port_opened?).to be true
    expect(vm.exist_on_hv?).to be true
  end

  it 'Suspend/Unsuspend Virtual Machine' do
    vm.suspend
    expect(vm.exist_on_hv?).to be false
    vm.start_up
    expect(vm.api_response_code).to eq '422'
    vm.unsuspend
    vm.start_up
    expect(vm.port_opened?).to be true
  end

  describe 'Perform disk action' do
    before :all do
      @disks_count_before_test = @vm.disks.count
      @disk = @vm.add_disk
      @disk.wait_for_build
    end

    it 'VM should be accessible after disk increasing' do
      new_disk_size = @disk.disk_size + 2
      @disk.edit(disk_size: new_disk_size)
      expect(vm.port_opened?).to be true
    end

    it 'disk decreasing should be blocked' do
      new_disk_size = @disk.disk_size - 1
      expect(@disk.edit(disk_size: new_disk_size)).to be nil
    end

    it 'VM should be accessible after primary disk increasing' do
      new_disk_size = vm.disk.disk_size + 2
      vm.disk.edit(disk_size: new_disk_size)
      expect(vm.port_opened?).to be true
    end

    it 'primary disk decreasing should be blocked' do
      new_disk_size = vm.disk.disk_size - 1
      expect(vm.disk.edit(disk_size: new_disk_size)).to be nil
    end

    it 'should be impossible to add second primary disk with template min_disk_size to VS' do
      vm.add_disk(primary: true, primary_disk_size: vm.template.min_disk_size)
      expect(vm.api_response_code).to eq '422'
    end


    it 'should be impossible to add second primary disk with minimal available size to VS' do
      vm.add_disk(primary: true)
      expect(vm.api_response_code).to eq '422'
    end

    # it 'primary disk should be migrated if there is available DS on a cloud' do
    #   if vm.disk.available_data_store_for_migration
    #     vm.disk.migrate
    #     expect(vm.port_opened?).to be true
    #   else
    #     skip("skipped because we have not found available data stores for migration.")
    #   end
    # end
    #
    # it 'additional disk should be migrated if there is additional DS' do
    #   if @disk.available_data_store_for_migration
    #     @disk.migrate
    #     expect(vm.port_opened?).to be true
    #   else
    #     skip("skipped because we have not found available data stores for migration.")
    #   end
    # end

    it 'additional disk should be removed' do
      @disk.remove
      expect(vm.disks.count).to eq @disks_count_before_test
    end
  end

  describe 'IP addresses' do
    before :all do
      @vm.network_interface.allocate_new_ip
      @vm.rebuild_network
      @primary_network_interface_exist = @vm.network_interface.any?
      @free_addresses = @vm.network_interface.ip_address.all
    end

    before do
      fail('Primary network interface does not exist') unless @primary_network_interface_exist
      skip('There are no free ip addresses') if @free_addresses.empty?
    end

    it 'Second IP address should be appeared in the interface' do
      expect(vm.ip_addresses.count).to eq 2
    end

    it 'All IPs should be accessible' do
      expect(vm.ip_addresses.first.port_opened?).to be true
      expect(vm.ip_addresses.last.port_opened?).to be true
    end
  end

  describe 'Reboot in recovery operation' do
    it 'Reboot in recovery Operations' do
      skip('Could not connect to private ip') if vm.network_interface.ip_address.private?
      vm.reboot(recovery: true)
      expect(vm.port_opened?).to be true
      creds = {'vm_host' => vm.ip_address, 'vm_pass' => vm.initial_root_password}
      expect(vm.interface.execute_with_pass(creds, 'hostname')).to include 'recovery'
      vm.reboot
      expect(vm.port_opened?).to be true
    end
  end

  describe 'Network interfaces' do
    before :all do
      @ids = @vm.available_network_join_ids
    end

    before do
      skip('Additional network has not been attached to HV or HVZ') if @ids.empty?
    end

    it 'Attach new' do
      amount = vm.network_interfaces.count
      vm.attach_network_interface
      expect(vm.network_interfaces.count).to eq amount + 1
    end

    it 'Detach' do
      amount = vm.network_interfaces.count
      vm.network_interface('additional').remove
      expect(vm.network_interfaces.count).to eq amount - 1
    end

    it 'Detach primary network interface and attach again' do
      ip = vm.ip_address
      vm.network_interface.remove
      expect(vm.port_closed?(remote_ip: ip)).to be true
      vm.attach_network_interface(primary: true)
      vm.network_interface.allocate_new_ip
      vm.rebuild_network
      expect(vm.port_opened?).to be true
    end
  end
end
