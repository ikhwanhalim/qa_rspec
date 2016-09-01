require 'spec_helper'
require './groups/virtual_server_build_from_iso'

describe 'Virtual Server build from ISO actions tests' do
  before :all do
    @ivsa = IsoVirtualServerActions.new.precondition
    if @ivsa
      @vm = @ivsa.virtual_machine
      @iso = @ivsa.iso
    else
      fail('/data not mounted')
    end
  end

  after :all do
    if @ivsa
      @vm.destroy
      @iso.remove
    end
  end

  let(:vm) { @ivsa.virtual_machine }
  let(:iso) { @ivsa.iso }

  describe 'VM power operations' do
    it { expect(vm.exist_on_hv?).to be true }

    it 'Stop/Start Virtual Machine' do
      vm.stop
      expect(vm.exist_on_hv?).to be false
      vm.start_up
      expect(vm.exist_on_hv?).to be true
    end

    it 'ShutDown/Start Virtual Machine' do
      vm.shut_down
      expect(vm.exist_on_hv?).to be false
      vm.start_up
      expect(vm.exist_on_hv?).to be true
    end

    it 'Reboot Virtual Machine' do
      vm.reboot
      expect(vm.exist_on_hv?).to be true
    end

    it 'Suspend/Unsuspend Virtual Machine' do
      vm.suspend
      expect(vm.exist_on_hv?).to be false
      vm.start_up
      expect(vm.api_response_code).to eq '422'
      vm.unsuspend
      vm.start_up
      expect(vm.exist_on_hv?).to be true
    end

    it 'Reboot in recovery mode' do
      skip('Could not connect to private ip') if vm.network_interface.ip_address.private?
      vm.reboot(recovery: true)
      expect(vm.port_opened?).to be true
      creds = {'vm_host' => vm.ip_address, 'vm_pass' => 'recovery'}
      expect(vm.interface.execute_with_pass(creds, 'hostname')).to include 'recovery'
    end
  end

  describe 'ISO' do
    before :all do
      @iso_new = Iso.new(@ivsa)
      @is_folder_mounted = @ivsa.hypervisor.is_data_mounted?
      @iso_new.create(min_disk_size: 3) if @is_folder_mounted
    end

    after :all do
      @vm.info_update.booted ? @vm.reboot : @vm.start_up
      @iso_new.remove if @is_folder_mounted
    end

    before { skip('The data folder isn\'t mounted on HV') unless @is_folder_mounted }

    let(:iso_new) { @iso_new }
    let(:hypervisor) { @ivsa.hypervisor }

    it 'ISO file should exist on HV' do
      hypervisor.remount_data unless hypervisor.find_exist('/data', iso_new.file_name)
      expect(hypervisor.find_exist('/data', iso_new.file_name)).to be true
    end

    it 'Reboot VS from ISO' do
      skip('Virtual Server cannot be rebooted from this ISO') if !vm.can_be_booted_from_iso?(iso_new)
      vm.reboot_from_iso(iso_new.id)
      expect(vm.api_response_code).to eq '200'
      expect(vm.exist_on_hv?).to be true
    end

    it 'Boot VS from ISO' do
      skip('Virtual Server cannot be booted from this ISO') if !vm.can_be_booted_from_iso?(iso_new)
      vm.shut_down if vm.exist_on_hv?
      expect(vm.exist_on_hv?).to be false
      vm.boot_from_iso(iso_new.id)
      expect(vm.api_response_code).to eq '200'
      expect(vm.exist_on_hv?).to be true
    end

    context 'Negative' do
      before do
        iso_new.edit(min_memory_size: vm.memory.to_i - 1, min_disk_size: vm.total_disk_size - 1)
      end

      it 'Reboot VS from ISO if not enough memory' do
        iso_new.edit(min_memory_size: vm.memory.to_i + 10)
        vm.reboot_from_iso(iso_new.id)
        expect(vm.api_response_code).to eq '422'
        expect(vm.exist_on_hv?).to be true
      end

      it 'Reboot VS from ISO if incorrect virtualization type' do
        skip("https://onappdev.atlassian.net/browse/CORE-5721")
        virt = vm.hypervisor_type == 'xen' ? 'kvm' : 'xen'
        iso_new.edit(virtualization: virt, min_memory_size: vm.memory.to_i)
        vm.reboot_from_iso(iso_new.id)
        expect(vm.api_response_code).to eq '422'
        expect(vm.exist_on_hv?).to be true
      end

      it 'Reboot VS from ISO if not enough disk space' do
        iso_new.edit(min_disk_size: vm.total_disk_size + 10)
        vm.reboot_from_iso(iso_new.id)
        expect(vm.api_response_code).to eq '422'
        expect(vm.exist_on_hv?).to be true
      end

      it 'Boot VS from ISO if not enough memory' do
        iso_new.edit(min_memory_size: vm.memory.to_i + 10)
        vm.shut_down if vm.exist_on_hv?
        expect(vm.exist_on_hv?).to be false
        vm.boot_from_iso(iso_new.id)
        expect(vm.api_response_code).to eq '422'
        expect(vm.exist_on_hv?).to be false
      end

      it 'Boot VS from ISO if incorrect virtualization type' do
        skip("https://onappdev.atlassian.net/browse/CORE-5721")
        virt = vm.hypervisor_type == 'xen' ? 'kvm' : 'xen'
        iso_new.edit(virtualization: virt, min_memory_size: vm.memory.to_i, min_disk_size: vm.total_disk_size - 1)
        vm.shut_down if vm.exist_on_hv?
        expect(vm.exist_on_hv?).to be false
        vm.boot_from_iso(iso_new.id)
        expect(vm.api_response_code).to eq '422'
        expect(vm.exist_on_hv?).to be false
      end

      it 'Boot VS from ISO if not enough disk space' do
        iso_new.edit(min_disk_size: vm.total_disk_size + 10, min_memory_size: vm.memory.to_i)
        vm.shut_down if vm.exist_on_hv?
        expect(vm.exist_on_hv?).to be false
        vm.boot_from_iso(iso_new.id)
        expect(vm.api_response_code).to eq '422'
        expect(vm.exist_on_hv?).to be false
      end
    end
  end
end

