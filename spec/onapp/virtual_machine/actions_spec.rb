require 'spec_helper'
require './groups/virtual_server_actions'

describe 'Virtual Server actions tests' do
  before :all do
    @vsa = VirtualServerActions.new.precondition
    @vm = @vsa.virtual_machine
  end

  after :all do
    @vm.destroy
  end

  let(:vm) { @vsa.virtual_machine }

  describe 'VM power operations' do
    describe 'After build' do
      it { expect(vm.pinged?).to be true }

      it { expect(vm.exist_on_hv?).to be true }
    end

    it 'Stop/Start Virtual Machine' do
      vm.stop
      expect(vm.not_pinged?).to be true
      vm.start_up
      expect(vm.pinged? && vm.exist_on_hv?).to be true
    end

    it 'ShutDown/Start Virtual Machine' do
      vm.shut_down
      expect(vm.not_pinged?).to be true
      vm.start_up
      expect(vm.pinged? && vm.exist_on_hv?).to be true
    end

    it 'Reboot Virtual Machine' do
      vm.reboot
      expect(vm.pinged? && vm.exist_on_hv?).to be true
    end

    it 'Suspend/Unsuspend Virtual Machine' do
      vm.suspend
      expect(vm.not_pinged?).to be true
      expect(vm.exist_on_hv?).to be false
      vm.start_up
      expect(vm.api_response_code).to eq '422'
      vm.unsuspend
      vm.start_up
      expect(vm.pinged? && vm.exist_on_hv?).to be true
    end
  end

  describe 'Perform disk action' do
    before :all do
      @disks_count_before_test = @vm.disks.count
      @disk = @vm.add_disk
      @disk.wait_for_build
    end


    it 'additional disk size should be increased' do
      new_disk_size=@disk.disk_size+2
      @disk.edit(disk_size: new_disk_size, add_to_linux_fstab: true)
      expect(vm.port_opened?).to be true
      expect(vm.disk('additional').disk_size_compare_with_interface).to eq true
    end

    it 'additional disk size should be decreased' do
      new_disk_size=@disk.disk_size-1
      @disk.edit(disk_size: new_disk_size, add_to_linux_fstab: true)
      expect(vm.port_opened?).to be true
      expect(vm.disk('additional').disk_size_compare_with_interface).to eq true
    end

    it 'primary disk size should be increased on virtual server' do
      new_disk_size = vm.disk.disk_size + 2
      vm.disk.edit(disk_size: new_disk_size)
      expect(vm.port_opened?).to be true
      expect(vm.disk.disk_size_compare_with_interface).to eq true
    end

    it 'primary disk size should be decreased on virtual server' do
      new_disk_size = vm.disk.disk_size - 1
      vm.disk.edit(disk_size: new_disk_size)
      expect(vm.port_opened?).to be true
      expect(vm.disk.disk_size_compare_with_interface).to eq true
    end

    it 'should be impossible to add second primary disk with template min_disk_size to VS' do
      vm.add_disk(primary: true, primary_disk_size: vm.template.min_disk_size)
      expect(vm.api_response_code).to eq '422'
      expect(vm.disks.count).to eq @disks_count_before_test+1
    end


    it 'should be impossible to add second primary disk with minimal available size to VS' do
      skip("Uncomment this test in 4.2. This test brakes VM functionality rebuild VM is required if run it in 4.1")
      # vm.add_disk(primary: true)
      # expect(vm.api_response_code).to eq '422' #bug core-3333 fixed in 4.2
      # expect(vm.disks.count).to eq @disks_count_before_test+1
    end

    it 'additional disk should be mounted' do
      expect(vm.port_opened?).to be true
      expect(vm.disk_mounted?(@disk)).to be true
    end


    it 'default swap disk size should be mounted and actual size should be equal to UI value' do
      expect(vm.port_opened?).to be true
      expect(vm.disk('swap').disk_size_compare_with_interface).to eq true
    end

    it 'should be possible to add and remove additional swap disk' do
      additiona_swap_disk = vm.add_disk(is_swap: true, disk_size: 2)
      additiona_swap_disk.wait_for_build
      expect(vm.port_opened?).to be true
      expect(vm.disk('swap').disk_size_compare_with_interface).to eq false #this can be refactored to determine each swap disk separately
      additiona_swap_disk.remove
      #additiona_swap_disk.wait_for_destroy
      expect(vm.port_opened?).to be true
      expect(vm.disk('swap').disk_size_compare_with_interface).to eq true
    end

    it 'should be possible increase size of swap disk' do
      new_swap_disk_size=vm.disk('swap').disk_size+2
      vm.disk('swap').edit(disk_size: new_swap_disk_size)
      expect(vm.port_opened?).to be true
      expect(vm.disk('swap').disk_size_compare_with_interface).to eq true
    end

    it 'should be possible decrease size of swap disk' do
      new_swap_disk_size=vm.disk('swap').disk_size-1
      vm.disk('swap').edit(disk_size: new_swap_disk_size)
      expect(vm.port_opened?).to be true
      expect(vm.disk('swap').disk_size_compare_with_interface).to eq true
    end

    it 'primary disk should be migrated if there is available DS on a cloud' do
      if !vm.disk.available_data_store_for_migration.nil?
        vm.disk.migrate
        expect(vm.port_opened?).to be true
      else
        skip("skipped because we have not found available data stores for migration.")
      end
    end

    it 'additional disk should be migrated if there is additional DS' do
      if @disk.available_data_store_for_migration!=nil
        @disk.migrate
        expect(vm.port_opened?).to be true
      else
        skip("skipped because we have not found available data stores for migration.")
      end
    end

    it 'additional disk should be removed' do
      @disk.remove
      expect(vm.disks.count).to eq @disks_count_before_test
    end
  end

  describe 'Network operations' do
    describe 'Network interfaces' do
      before :all do
        @ids = @vm.available_network_join_ids
      end

      before { skip('Additional network has not been attached to HV or HVZ') if @ids.empty? }

      it 'Attach new' do
        amount = vm.network_interface.amount
        vm.attach_network_interface
        expect(vm.network_interface.amount).to eq amount + 1
      end

      it 'Detach' do
        amount = vm.network_interface.amount
        vm.network_interface('additional').remove
        expect(vm.network_interface.amount).to eq amount - 1
      end

      it 'Detach primary network interface and attach again' do
        ip = vm.ip_address
        vm.network_interface.remove
        expect(vm.not_pinged?(ip)).to be true
        vm.attach_network_interface(primary: true)
        vm.network_interface.allocate_new_ip
        vm.rebuild_network
        expect(vm.pinged?).to be true
      end

      it 'Ability create two primary interfaces should be blocked' do
        skip
      end
    end

    describe 'IP addresses' do
      before :all do
        @vm.network_interface.allocate_new_ip
        @vm.rebuild_network
      end

      it 'Second IP address should be appeared in the interface' do
        expect(vm.ip_addresses.count).to eq 2
      end

      it 'All IPs should be visible inside VM' do
        expect(vm.ip_addresses.map &:exist_on_vm).to_not include false
      end

      it 'All IPs should pinged' do
        expect(vm.ip_addresses.map &:pinged?).to_not include false
      end

      it 'Allocate used IP' do
        skip
      end
    end

    describe 'Firewall rules' do
      it 'Set DROP default rule' do
        skip
      end

      it 'Set DROP rule for TCP custom port' do
        skip
      end

      it 'Set DROP rule for ICMP' do
        skip
      end
    end
  end

  describe 'Reboot in recovery operation' do
    it 'Reboot in recovery Operations' do
      vm.reboot(recovery: true)
      expect(vm.port_opened?).to be true
      expect(vm.ssh_execute('hostname')).to include 'recovery'
      vm.reboot
      expect(vm.port_opened?).to be true
      expect(vm.ssh_execute('hostname')).to include vm.hostname
    end
  end

#Reboot VS from ISO
  describe 'Reboot VS from ISO' do
    before :all do
      @vsa.iso = Iso.new(@vsa)
      @vsa.iso.create
      @is_folder_mounted = @vsa.iso.exists_on_hv?
    end

    after :all do
      @vsa.iso.remove
    end

    before { skip('The data folder isn\'t mounted on HV') unless @is_folder_mounted }

    let(:iso) { @vsa.iso }

    it 'Reboot VS from ISO' do
      skip('Virtual Server cannot be booted from this ISO') if !vm.can_be_booted_from_iso?
      vm.reboot_from_iso(iso.id)
      expect(vm.exist_on_hv?).to be true
    end

    it 'Reboot VS from ISO if not enough memory' do
      iso.edit(min_memory_size: vm.memory.to_i + 10)
      vm.reboot_from_iso(iso.id)
      expect(vm.exist_on_hv?).to be true
    end

    it 'Reboot VS from ISO if incorrect virtualization type' do
      vm.hypervisor_type == 'xen' ? iso.edit(virtualization: 'kvm') : iso.edit(virtualization: 'xen')
      vm.reboot_from_iso(iso.id)
      expect(vm.pinged?).to be true
    end

    it 'Boot VS from ISO' do
      skip('Virtual Server cannot be booted from this ISO') if !vm.can_be_booted_from_iso?
      vm.shut_down
      expect(vm.not_pinged?).to be true
      vm.boot_from_iso(iso.id)
      expect(vm.exist_on_hv?).to be true
    end
  end
end