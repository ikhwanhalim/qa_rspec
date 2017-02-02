require 'spec_helper'
require './groups/virtual_server_built_from_iso'

describe 'Virtual Server built from ISO actions tests' do
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
      @vm.destroy unless IsoVirtualServerActions::IDENTIFIER
      @iso.remove unless IsoVirtualServerActions::ISO_ID
    end
  end

  let(:vm) { @ivsa.virtual_machine }
  let(:iso) { @ivsa.iso }

  describe 'Option cdboot' do
    it 'Option cdboot should be true for VS built from ISO' do
      expect(vm.cdboot).to be true
    end

    it 'Disable cdboot option for VS built from ISO' do
      vm.boot_from_cd(status: 'disable')
      expect(vm.cdboot).to be false
    end

    it 'Enable cdboot option for VS built from ISO' do
      vm.boot_from_cd
      expect(vm.cdboot).to eq true
    end
  end

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

  describe 'Administrative Options' do
    it 'Reset VS root password for VS built from ISO should not be supported' do
      expect(vm.reset_root_password['errors']).to eq(["The action is not available to the virtual server because it's built from ISO."])
      expect(vm.api_response_code).to eq '422'
    end

    it 'Set SSH keys for VS built from ISO should not be supported' do
      expect(vm.set_ssh_keys['errors']).to eq(["The action is not available to the virtual server because it's built from ISO."])
      expect(vm.api_response_code).to eq '422'
    end
  end

  describe 'Boot/Reboot from ISO' do
    before :all do
      @iso_new = Iso.new(@ivsa)
      @is_folder_mounted = @ivsa.hypervisor.is_data_mounted?
      @iso_new.create() if @is_folder_mounted
      @iso_path = @ivsa.settings.iso_path_on_hv
    end

    after :all do
      @vm.info_update.booted ? @vm.reboot : @vm.start_up
      @iso_new.remove if @is_folder_mounted
    end

    before { skip('The data folder isn\'t mounted on HV') unless @is_folder_mounted }

    let(:iso_new) { @iso_new }
    let(:hypervisor) { @ivsa.hypervisor }

    it 'ISO file should exist on HV' do
      hypervisor.remount_data unless hypervisor.find_exist(@iso_path, iso_new.file_name)
      expect(hypervisor.find_exist(@iso_path, iso_new.file_name)).to be true
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
      it 'Reboot VS from ISO if not enough memory' do
        iso_new.edit(min_memory_size: vm.memory.to_i + 10)
        expect(vm.reboot_from_iso(iso_new.id)['error']).to eq("Virtual server must have at least #{iso_new.min_memory_size}MB of RAM")
        expect(vm.api_response_code).to eq '422'
        expect(vm.exist_on_hv?).to be true
      end

      it 'Reboot VS from ISO if incorrect virtualization type' do
        virt = vm.hypervisor_type == 'xen' ? 'kvm' : 'xen'
        iso_new.edit(virtualization: virt)
        expect(vm.reboot_from_iso(iso_new.id)['error']).to eq("Template virtualization is not compatible with compute resource type")
        expect(vm.api_response_code).to eq '422'
        expect(vm.exist_on_hv?).to be true
      end

      it 'Reboot VS from ISO if not enough disk space' do
        iso_new.edit(min_disk_size: vm.total_disk_size + 10)
        expect(vm.reboot_from_iso(iso_new.id)['error']).to eq("Virtual server primary disk size must be at least #{iso_new.min_disk_size}GB")
        expect(vm.api_response_code).to eq '422'
        expect(vm.exist_on_hv?).to be true
      end

      it 'Boot VS from ISO if not enough memory' do
        iso_new.edit(min_memory_size: vm.memory.to_i + 10)
        vm.shut_down if vm.exist_on_hv?
        expect(vm.exist_on_hv?).to be false
        expect(vm.boot_from_iso(iso_new.id)['error']).to eq("Virtual server must have at least #{iso_new.min_memory_size}MB of RAM")
        expect(vm.api_response_code).to eq '422'
        expect(vm.exist_on_hv?).to be false
      end

      it 'Boot VS from ISO if incorrect virtualization type' do
        virt = vm.hypervisor_type == 'xen' ? 'kvm' : 'xen'
        iso_new.edit(virtualization: virt)
        vm.shut_down if vm.exist_on_hv?
        expect(vm.exist_on_hv?).to be false
        expect(vm.boot_from_iso(iso_new.id)['error']).to eq("Template virtualization is not compatible with compute resource type")
        expect(vm.api_response_code).to eq '422'
        expect(vm.exist_on_hv?).to be false
      end

      it 'Boot VS from ISO if not enough disk space' do
        iso_new.edit(min_disk_size: vm.total_disk_size + 10)
        vm.shut_down if vm.exist_on_hv?
        expect(vm.exist_on_hv?).to be false
        expect(vm.boot_from_iso(iso_new.id)['error']).to eq("Virtual server primary disk size must be at least #{iso_new.min_disk_size}GB")
        expect(vm.api_response_code).to eq '422'
        expect(vm.exist_on_hv?).to be false
      end
    end
  end

  describe 'Rebuild VS' do
    it 'Rebuild VS built from ISO should not be supported' do
      expect(vm.rebuild['errors']).to eq(["The action is not available to the virtual server because it's built from ISO."])
      expect(vm.api_response_code).to eq '422'
    end
  end

  describe 'Disk operations' do
    before :each do
      @disk = vm.disk
    end

    let(:disk) { @disk }

    it 'Disk should be increased' do
      skip("Size for FreeBSD primary disk cannot be changed") if iso.operating_system == 'freebsd'
      new_disk_size = disk.disk_size + 2
      disk.edit(disk_size: new_disk_size)
      vm.wait_for_start
      expect(vm.exist_on_hv?).to be true
      expect(disk.disk_size).to eq new_disk_size
    end

    it 'Disk should not be decreased' do
      vm_disk_size = disk.disk_size
      new_disk_size = disk.disk_size - 2
      disk.edit(disk_size: new_disk_size)
      expect(vm.api_response_code).to eq '422'
      expect(disk.errors['disk_size']).to eq(['cannot be decreased for VM built from ISO template'])
      expect(vm.exist_on_hv?).to be true
      expect(disk.disk_size).to eq vm_disk_size
    end

    it 'Add and remove an additional disk' do
      disks_count_before_test = vm.disks.count
      new_disk = vm.add_disk
      new_disk.wait_for_build
      expect(vm.exist_on_hv?).to be true
      expect(vm.disks.count).to eq disks_count_before_test + 1
      new_disk.remove
      expect(vm.exist_on_hv?).to be true
      expect(vm.disks.count).to eq disks_count_before_test
    end

    it 'Disk should be migrated if there is available DS on a cloud' do
      if disk.available_data_store_for_migration
        disk.migrate
        expect(vm.exist_on_hv?).to be true
      else
        skip('skipped because we have not found available data stores for migration.')
      end
    end
  end

  describe 'Backups' do

    before { @incremental_backups_enabled = @ivsa.settings.allow_incremental_backups }

    it 'Normal backups should not be supported for VS built from ISO' do
      if !@incremental_backups_enabled
        expect(vm.disk.create_backup['base']).to eq(['Backups are not supported'])
        expect(vm.api_response_code).to eq '422'
        expect(vm.exist_on_hv?).to be true
      else
        skip('Skipped as normal backups are disabled at CP settings')
      end
    end

    it 'Incremental backups should not be supported for VS built from ISO' do
      #TODO
      skip('https://onappdev.atlassian.net/browse/CORE-7781')
      if @incremental_backups_enabled
        expect(vm.create_backup['base']).to eq(['Backups are not supported'])
        expect(vm.api_response_code).to eq '422'
        expect(vm.exist_on_hv?).to be true
       else
         skip('Skipped as incremental backups are disabled at CP settings')
      end
    end

    it 'Getting all backups for VS built from ISO should return error' do
      expect(vm.get_backups['errors']).to eq(["The action is not available to the virtual server because it's built from ISO."])
      expect(vm.api_response_code).to eq '422'
    end

    it 'Getting normal backups for VS built from ISO should return error' do
      expect(vm.get_backups('normal')['errors']).to eq(["The action is not available to the virtual server because it's built from ISO."])
      expect(vm.api_response_code).to eq '422'
    end

    it 'Getting incremental backups for VS built from ISO should return error' do
      expect(vm.get_backups('incremental')['errors']).to eq(["The action is not available to the virtual server because it's built from ISO."])
      expect(vm.api_response_code).to eq '422'
    end

    it 'Getting disk backups for VS built from ISO should return error' do
      #TODO
      skip('https://onappdev.atlassian.net/browse/CORE-7781')
      expect(vm.disk.get_backups['errors']).to eq(["The action is not available to the virtual server because it's built from ISO."])
      expect(vm.api_response_code).to eq '422'
    end
  end

  describe 'Network operations' do
    it 'Add and remove an IP address' do
      skip('There are no free ip addresses') if vm.network_interface.ip_address.all.empty?
      ips_count_before_test = vm.ip_addresses.count
      vm.network_interface.allocate_new_ip
      expect(vm.ip_addresses.count).to eq ips_count_before_test + 1
      vm.network_interface.remove_ip(1)
      expect(vm.ip_addresses.count).to eq ips_count_before_test
    end

    it 'Attach network interface' do
      skip('Additional network has not been attached to HV or HVZ') if vm.available_network_join_ids.empty?
      vm.attach_network_interface
      expect(vm.network_interfaces.count).to eq 2
    end

    it 'Detach network interface' do
      skip('Additional network has not been attached to HV or HVZ') if vm.available_network_join_ids.empty?
      vm.network_interface('additional').remove
      expect(vm.network_interfaces.count).to eq 1
    end

    it 'Rebuild Network should not be supported for VS built from ISO' do
      expect(vm.rebuild_network['errors']).to eq(["The action is not available to the virtual server because it's built from ISO."])
      expect(vm.api_response_code).to eq '422'
    end
  end

  describe 'Firewall rules' do
    after do
      vm.network_interface.reset_firewall_rules
      vm.update_firewall_rules
    end

    it 'Set DROP default rule' do
      vm.network_interface.set_default_firewall_rule('DROP')
      vm.update_firewall_rules
      expect(vm.api_response_code).to eq '200'
    end

    it 'Set DROP rule for TCP custom port' do
      vm.network_interface.add_custom_firewall_rule(command: 'DROP')
      vm.update_firewall_rules
      expect(vm.api_response_code).to eq '200'
    end

    it 'Set DROP rule for ICMP' do
      vm.network_interface.add_custom_firewall_rule(command: 'DROP', protocol: 'ICMP')
      vm.update_firewall_rules
      expect(vm.api_response_code).to eq '200'
    end
  end
end

