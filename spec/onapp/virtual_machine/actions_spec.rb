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
      @disks_count_before_test=vm.disks.count
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
      new_disk_size= vm.disk.disk_size+2
      vm.disk.edit(disk_size: new_disk_size)
      expect(vm.port_opened?).to be true
      expect(vm.disk.disk_size_compare_with_interface).to eq true
    end

    it 'primary disk size should be decreased on virtual server' do
      new_disk_size= vm.disk.disk_size-1
      vm.disk.edit(disk_size: new_disk_size)
      expect(vm.port_opened?).to be true
      expect(vm.disk.disk_size_compare_with_interface).to eq true
    end

    it 'should be impossible to add second primary disk to VS' do
      vm.add_disk(primary: true)
      expect(vm.api_response_code).to eq '422' #bug core-3333 fixed in 4.2
      expect(vm.disks.count).to eq @disks_count_before_test+1
    end

    it 'additional disk should be mounted' do
      expect(vm.port_opened?).to be true
      expect(vm.disk_mounted?(@disk)).to be true
    end

    it 'additional disk should be migrated if there is additional DS' do
      skip
    end

    it 'additional disk should be removed' do
      @disk.remove
      expect(vm.disks.count).to eq @disks_count_before_test
    end




  end

  describe 'Network operations' do
    it 'Should be possible to do something' do
      skip
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
      @iso = @vsa.iso
      Log.error('The data folder isn\'t mounted on HV') unless @iso.exists_on_hv?
    end

    after :all do
      @iso.remove
    end

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