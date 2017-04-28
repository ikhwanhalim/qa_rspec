require 'spec_helper'
require './groups/virtual_server_built_from_iso'

describe 'Virtual Server built from ISO actions tests' do
  before :all do
    @ivsa = IsoVirtualServerActions.new.precondition
    if @ivsa
      @cp_version = @ivsa.version
      @vm = @ivsa.virtual_machine
      @iso = @ivsa.iso
      @hypervisor = @ivsa.hypervisor
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

  describe  'Admin/User note' do
    it 'Add admin note' do
      vm.add_note
      expect(vm.admin_note).to eq('admin note')
    end

    it 'Edit admin note' do
      vm.add_note(admin_note: true, note: 'edited admin note')
      expect(vm.admin_note).to eq('edited admin note')
    end

    it 'Delete admin note' do
      vm.remove_note('admin_note')
      expect(vm.admin_note).to be nil
    end

    it 'Add user note' do
      vm.add_note(admin_note: false, note: 'user note')
      expect(vm.note).to eq('user note')
    end

    it 'Edit user note' do
      vm.add_note(admin_note: false, note: 'edited user note')
      expect(vm.note).to eq('edited user note')
    end

    it 'Delete user note' do
      vm.remove_note('note')
      expect(vm.note).to be nil
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

    describe 'Change owner' do
      before do
        @new_user = User.new(@ivsa).create( first_name: 'Change',last_name: 'Owner',)
        @owner = vm.user_id
      end

      after do
        vm.change_owner(@owner)
        @new_user.remove
      end

      it 'Change owner' do
        vm.change_owner(@new_user.id)
        expect(vm.user_id).to eq @new_user.id
      end
    end

    it 'Reset VS root password for VS built from ISO should not be supported' do
      expect(vm.reset_root_password).to eq(["The action is not available to the virtual server because it's built from ISO."])
      expect(vm.api_response_code).to eq '422'
    end

    it 'Set SSH keys for VS built from ISO should not be supported' do
      expect(vm.set_ssh_keys).to eq(["The action is not available to the virtual server because it's built from ISO."])
      expect(vm.api_response_code).to eq '422'
    end
  end

  describe 'Migrate VS' do
    before do
      @hv = @hypervisor.available_hypervisor_for_migration
      skip('There is no available hypervisors for migration') unless @hv
      skip("The data folder is not mounted on selected hypervisor #{@hv.id}") unless @hv.is_data_mounted?
    end

    it 'Only cold migrate allowed' do
      expect(vm.booted).to be true
      vm.migrate(@hv.id, hot: false)
      expect(vm.hypervisor_id).to eq @hv.id
      expect(vm.exist_on_hv?).to be true
    end
  end

  describe 'Performance Options' do
    before :all do
      @hv = @hypervisor.available_hypervisor_for_migration
      if @hv && @hv.is_data_mounted?
        @vm_new = VirtualServer.new(@ivsa)
        @vm_new.create(hypervisor_id: @hv.id)
      else
        skip('There is no available hypervisors for segregation or data folder is not mounted on it')
      end
    end

    after :all do
      @vm_new.destroy if @vm_new
    end

    it 'Segregate VS' do
      vm.segregate(@vm_new.id)
      expect(vm.strict_virtual_machine_id).to eq @vm_new.id
      expect(vm.migrate(@hv.id, hot: false)['base']).to eq(['Virtual Server cannot be migrated'])
      expect(vm.api_response_code).to eq '422'
    end

    it 'Desegregate VS' do
      vm.desegregate(@vm_new.id)
      expect(vm.strict_virtual_machine_id).to be nil
      vm.migrate(@hv.id, hot: false)
      expect(vm.hypervisor_id).to eq @hv.id
      expect(vm.exist_on_hv?).to be true
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
        skip ("CORE-5721 fixed in Onapp 5.4, but this is OnApp #{@cp_version}") unless @cp_version >= 5.4
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
        skip ("CORE-5721 fixed in Onapp 5.4, but this is OnApp #{@cp_version}") unless @cp_version >= 5.4
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
      datastore_id = disk.available_data_store_for_migration
      if datastore_id
        disk.migrate(datastore_id)
        expect(vm.exist_on_hv?).to be true
        expect(disk.data_store_id).to eq datastore_id
      else
        skip('skipped because we have not found available data stores for migration.')
      end
    end
  end

  describe 'Backups' do

    before { skip ("Backups for VS built from ISO added in OnApp 5.4, but this is OnApp #{@cp_version}") unless @cp_version >= 5.4 }

    context 'Normal' do
      before :all do
        @backup = @vm.disk.create_backup
      end

      let(:backup) { @backup }

      it 'should not be visible in /files route' do
        ids = vm.get_backups('incremental').map { |b| b.backup.id }
        expect(ids).not_to include backup.id
      end

      it 'should be visible in /images route' do
        ids =  vm.get_backups('normal').map { |b| b.backup.id }
        expect(ids).to include backup.id
      end

      it 'should be visible in /disks/:disk_id/backups route' do
        ids =  vm.disk.get_backups.map { |b| b.backup.id }
        expect(ids).to include backup.id
      end

      it 'should restore from backup' do
        backup.restore
        expect(vm.exist_on_hv?).to be true
      end

      it 'should not convert to template' do
        expect(backup.convert['base']).to eq(["Conversion to template isn't supported by the backup's target."])
        expect(backup.api_response_code).to eq '422'
      end

      it 'should enable normal autobackups' do
        vm.disk.autobackup('enable')
        expect(vm.wait_for_building_backups).to be true
        expect(vm.disk.has_autobackups).to be true
      end

      it 'should be available if get all backups' do
        expect(vm.get_backups).not_to be_empty
        expect(vm.api_response_code).to eq '200'
      end
    end
  end

  describe 'Network operations' do
    it 'Add and remove an IP address' do
      (skip('There are no free ip addresses') if vm.network_interface.ip_address.all.empty?) if @cp_version < 5.4
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

    it 'Ability to create two primary interfaces should be blocked' do
      expect(vm.attach_network_interface(existed=false, primary: true)['primary']).to eq(["already has primary allocation."])
      expect(vm.network_interfaces.count).to eq 1
    end

    it 'Update port speed' do
      port_speed = 200
      vm.network_interface.edit(rate_limit: port_speed)
      expect(vm.network_interface.rate_limit).to eq port_speed
      expect(vm.network_interface.port_speed).to eq port_speed
    end

    it 'Edit network interface' do
      vm.network_interface.edit(label: 'eth1', primary: false)
      expect(vm.network_interface.label).to eq('eth1')
      expect(vm.network_interface.primary).to be false
      vm.network_interface.edit(primary: true)
      expect(vm.network_interface.primary).to be true
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

