require 'spec_helper'
require './groups/virtual_server_actions'

describe 'Virtual Server actions tests' do
  before :all do
    @vsa = VirtualServerActions.new.precondition
    @vm = @vsa.virtual_machine
  end

  after :all do
    @vm.destroy
    @vsa.iso.remove
  end

  let(:vm)  { @vsa.virtual_machine }
  let(:iso) { @vsa.iso }

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
      @disk = @vm.add_disk
      @disk.wait_for_build
    end

    it 'disk should be mounted' do
      expect(vm.port_opened?).to be true
      expect(vm.disk_mounted?(@disk)).to be true
    end

    it 'disk should be edited' do
      @disk.edit(disk_size: 2, add_to_linux_fstab: true)
      expect(vm.port_opened?).to be true
      expect(vm.disk('additional').disk_size_on_vm).to eq vm.disk('additional').disk_size
    end

    it 'primary disk should be edited on virtual server' do
      vm.disk.edit(disk_size: 6)
      expect(vm.port_opened?).to be true
      expect(vm.disk.disk_size_on_vm).to eq vm.disk.disk_size
    end

    it 'disk should be removed' do
      @disk.remove
      expect(vm.disks.count).to eq 2
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
    it 'Reboot VS from ISO' do
      skip('Virtual Server cannot be booted from this ISO') if !vm.can_be_booted_from_iso?
      vm.reboot_from_iso(iso.id)
      expect(vm.exist_on_hv?).to be true
    end

    it 'Reboot VS from ISO if not enough memory' do
      skip('Virtual Server can be booted from this ISO') if vm.can_be_booted_from_iso?
      vm.reboot_from_iso(iso.id)
      expect(vm.exist_on_hv?).to be true
      expect(vm.api_response_code).to eq '422'
    end
  end
end