require 'spec_helper'
require './groups/virtual_server_actions'

describe 'Virtual Server actions tests' do
  before :all do
    @vsa = VirtualServerActions.new.precondition
    @vm = @vsa.virtual_machine
    @template = @vsa.template
    @hypervisor = @vsa.hypervisor
  end

  after :all do
    unless VirtualServerActions::IDENTIFIER
      @vm.destroy
      @template.remove if @vm.find_by_template(@template.id).empty?
    end
  end

  let(:vm) { @vsa.virtual_machine }

  let(:version) { @vsa.version }

  it 'See own VMs through users_path users/:id/virtual_machines' do
    expect(@vsa.get("/users/#{vm.user_id}/virtual_machines")).not_to be_empty
  end

  describe 'VM power operations' do
    describe 'After build', :smoke do
      it { expect(vm.pinged?).to be true }

      it { expect(vm.exist_on_hv?).to be true }
    end

    it 'Stop/Start Virtual Machine' do
      vm.stop
      #binding.pry (added ssh_key onto cp server for user onapp)
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
      expect(vm.down?).to be true
      vm.start_up
      expect(vm.pinged? && vm.exist_on_hv?).to be true
    end

    it 'Reboot in recovery Operations' do
      #skip('Could not connect to private ip') if vm.network_interface.ip_address.private?
      vm.reboot(recovery: true)
      expect(vm.port_opened?).to be true
      creds = {'vm_host' => vm.ip_address, 'vm_pass' => vm.initial_root_password}
      expect(vm.interface.execute_with_pass(creds, 'hostname')).to include 'recovery'
      vm.reboot
      expect(vm.port_opened?).to be true
      expect(vm.ssh_execute('hostname').join(' ')).to match vm.hostname
    end
  end

  describe 'Administrative Options' do
    describe 'Reset root password' do
      before :all do
        @root_password = 'ownPassword123!'
        @passphrase = 'test'
      end

      let(:settings) { @vsa.settings }
      let(:root_password) {@root_password}
      let(:passphrase) {@passphrase}

      it 'Reset VS root password with generated password' do
        expect(vm.pinged? && vm.exist_on_hv?).to be true
        vm.reset_root_password
        expect(vm.up?).to be true
        creds = {'vm_host' => vm.ip_address, 'vm_pass' => vm.initial_root_password}
        expect(vm.interface.execute_with_pass(creds, 'hostname').join(' ')).to match vm.hostname
      end

      it 'Reset VS root password with own password' do
        expect(vm.pinged? && vm.exist_on_hv?).to be true
        vm.reset_root_password(root_pass: root_password)
        expect(vm.up?).to be true
        creds = {'vm_host' => vm.ip_address, 'vm_pass' => root_password}
        expect(root_password).to eq(vm.initial_root_password)
        expect(vm.interface.execute_with_pass(creds, 'hostname').join(' ')).to match vm.hostname
      end

      it 'Reset VS root password encrypt generated password' do
        skip('Allow VS password encryption option is disabled at CP settings') unless settings.allow_initial_root_password_encryption
        expect(vm.pinged? && vm.exist_on_hv?).to be true
        vm.reset_root_password(passphrase: passphrase, confirmation_passphrase: passphrase)
        expect(vm.up?).to be true
        response = vm.decrypt_root_password(passphrase)
        vm_pass = response['virtual_machine']['initial_root_password']
        creds = {'vm_host' => vm.ip_address, 'vm_pass' => vm_pass}
        expect(root_password).to_not eq(vm.initial_root_password)
        expect(vm.interface.execute_with_pass(creds, 'hostname').join(' ')).to match vm.hostname
      end

      it 'Reset VS root password set own password and encrypt' do
        skip('Allow VS password encryption option is disabled at CP settings') unless settings.allow_initial_root_password_encryption
        expect(vm.pinged? && vm.exist_on_hv?).to be true
        vm.reset_root_password(root_pass: root_password, passphrase: passphrase, confirmation_passphrase: passphrase)
        expect(vm.up?).to be true
        response = vm.decrypt_root_password(passphrase)
        vm_pass = response['virtual_machine']['initial_root_password']
        expect(root_password).to eq(vm_pass)
        creds = {'vm_host' => vm.ip_address, 'vm_pass' => vm_pass}
        expect(vm.interface.execute_with_pass(creds, 'hostname').join(' ')).to match vm.hostname
      end

      it 'Reset VS root password decrypt root password with incorrect passphrase' do
        skip('Allow VS password encryption option is disabled at CP settings') unless settings.allow_initial_root_password_encryption
        expect(vm.pinged? && vm.exist_on_hv?).to be true
        vm.reset_root_password(passphrase: passphrase, confirmation_passphrase: passphrase)
        expect(vm.up?).to be true
        response = vm.decrypt_root_password('testttttt')
        expect(response['errors']).to eq(['Encryption passphrase is invalid'])
      end

      it 'Reset VS root password encrypt generated password with incorrect confirmation passphrase' do
        skip('Allow VS password encryption option is disabled at CP settings') unless settings.allow_initial_root_password_encryption
        expect(vm.pinged? && vm.exist_on_hv?).to be true
        response = vm.reset_root_password(passphrase: passphrase, confirmation_passphrase: 'testttttt')
        expect(vm.up?).to be true
        expect(response['errors']['initial_root_password_encryption_key_confirmation']).to eq(["doesn't match confirmation"])
        expect(response['errors']['base']).to eq(['Virtual server root password cannot be reset at the moment. '])
      end

      it 'Reset VS root password set own password and encrypt with incorrect confirmation passphrase' do
        skip('Allow VS password encryption option is disabled at CP settings') unless settings.allow_initial_root_password_encryption
        expect(vm.pinged? && vm.exist_on_hv?).to be true
        response = vm.reset_root_password(root_pass: root_password, passphrase: passphrase, confirmation_passphrase: 'testttt')
        expect(vm.up?).to be true
        expect(response['errors']['initial_root_password_encryption_key_confirmation']).to eq(["doesn't match confirmation"])
        expect(response['errors']['base']).to eq(['Virtual server root password cannot be reset at the moment. '])
      end
    end

    describe 'Set SSH keys' do
      before :all do
        @vsa.user = User.new(@vsa)
        @vsa.user.find(@vm.user_id)
      end

      let(:user) { @vsa.user }

      it 'Add SSH key to user profile' do
        user.add_ssh_key
        expect(user.api_response_code).to eq '201'
      end

      it 'Set SSH keys' do
        vm.set_ssh_keys
        expect(vm.api_response_code).to eq '200'
        expect(vm.up?).to be true
        expect(vm.interface.execute_with_keys(vm.ip_address, 'root', 'hostname')).to match vm.hostname
      end

      it 'Remove SSH key from user profile' do
        user.remove_ssh_key
        expect(user.api_response_code).to eq '204'
      end
    end
  end

  describe 'Migrate VS' do
    before do
      @hv = @hypervisor.available_hypervisor_for_migration
      skip('There is no available hypervisors for migration') unless @hv
    end

    it 'Hot Migrate VS' do
      expect(vm.up?).to be true
      vm.migrate(@hv.id)
      expect(vm.hypervisor_id).to eq @hv.id
      expect(vm.exist_on_hv?).to be true
    end

    it 'Cold Migrate VS' do
      vm.stop
      expect(vm.down?).to be true
      vm.migrate(@hv.id,  hot: false)
      expect(vm.hypervisor_id).to eq @hv.id
      vm.start_up
      expect(vm.exist_on_hv?).to be true
    end
  end

  describe 'Performance Options' do
    before :all do
      @hv = @hypervisor.available_hypervisor_for_migration
      if @hv
        @vm_new = VirtualServer.new(@vsa)
        @vm_new.create(hypervisor_id: @hv.id)
      else
        skip('There is no available hypervisors for segregation')
      end
    end

    after :all do
      @vm_new.destroy
    end

    it 'Segregate VS' do
      vm.segregate(@vm_new.id)
      expect(vm.strict_virtual_machine_id).to eq @vm_new.id
      expect(vm.migrate(@hv.id)['base']).to eq(['Virtual Server cannot be migrated'])
      expect(vm.api_response_code).to eq '422'
    end

    it 'Desegregate VS' do
      vm.desegregate(@vm_new.id)
      expect(vm.strict_virtual_machine_id).to be nil
      vm.migrate(@hv.id)
      expect(vm.hypervisor_id).to eq @hv.id
      expect(vm.exist_on_hv?).to be true
    end
  end

  describe 'Perform disk action' do
    before :all do
      @disks_count_before_test = @vm.disks.count
      @disk = @vm.add_disk
      @disk.wait_for_build
    end

    def hot_actions_supported?
      @vsa.hypervisor.distro != "centos5" && @vsa.template.virtualization.include?('virtio') &&
          @vsa.hypervisor.hypervisor_type == 'kvm'
    end

    it 'additional disk size should be increased' do
      new_disk_size = @disk.disk_size + 2
      @disk.edit(disk_size: new_disk_size, add_to_linux_fstab: true)
      expect(vm.port_opened?).to be true
      expect(vm.disk('additional').disk_size_compare_with_interface).to eq true
    end

    it 'additional disk size should be decreased' do
      new_disk_size = @disk.disk_size - 1
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
    end

    it 'should be impossible to add second primary disk with minimal available size to VS' do
      vm.add_disk(primary: true)
      expect(vm.api_response_code).to eq '422'
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
      additional_swap_disk = vm.add_disk(is_swap: true, disk_size: 2)
      additional_swap_disk.wait_for_build
      expect(vm.port_opened?).to be true
      expect(vm.disk('swap').disk_size_compare_with_interface).to eq false #this can be refactored to determine each swap disk separately
      additional_swap_disk.remove
      expect(vm.port_opened?).to be true
      expect(vm.disk('swap').disk_size_compare_with_interface).to eq true
    end

    it 'should be possible increase size of swap disk' do
      new_swap_disk_size=vm.disk('swap').disk_size + 2
      vm.disk('swap').edit(disk_size: new_swap_disk_size)
      expect(vm.port_opened?).to be true
      expect(vm.disk('swap').disk_size_compare_with_interface).to eq true
    end

    it 'should be possible decrease size of swap disk' do
      new_swap_disk_size=vm.disk('swap').disk_size - 1
      vm.disk('swap').edit(disk_size: new_swap_disk_size)
      expect(vm.port_opened?).to be true
      expect(vm.disk('swap').disk_size_compare_with_interface).to eq true
    end

    it 'primary disk should be migrated if there is available DS on a cloud' do
      datastore_id = vm.disk.available_data_store_for_migration
      if datastore_id
        vm.disk.migrate(datastore_id)
        expect(vm.port_opened?).to be true
        expect(vm.disk.data_store_id).to eq datastore_id
      else
        skip("skipped because we have not found available data stores for migration.")
      end
    end

    it 'additional disk should be migrated if there is additional DS' do
      datastore_id = @disk.available_data_store_for_migration
      if datastore_id
        @disk.migrate(datastore_id)
        expect(vm.port_opened?).to be true
        expect(@disk.data_store_id).to eq datastore_id
      else
        skip("skipped because we have not found available data stores for migration.")
      end
    end

    it 'additional disk should be removed' do
      @disk.remove
      expect(vm.disks.count).to eq @disks_count_before_test
    end

    it 'additional disk should be hot attached/detached' do
      skip('Hot actions not supported') unless hot_actions_supported?
      expect(vm.pinged?).to be true
      disk = vm.add_disk(hot_attach: 1)
      disk.wait_for_attach
      expect(disk.disk_size_compare_with_interface).to be true
      disk.detach
    end

    it 'increase disk size during unlocking' do
      disk = vm.add_disk
      disk.wait_for_lock
      disk.unlock
      new_disk_size = disk.disk_size + 1
      disk.edit(disk_size: new_disk_size, add_to_linux_fstab: true)
      expect(vm.port_opened?).to be true
      expect(disk.disk_size).to eq new_disk_size
      expect(disk.disk_size_compare_with_interface).to eq true
    end
  end

  describe 'Network operations' do
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

      it 'All IPs should be pinged and visible inside VM' do
        ping_states = vm.ip_addresses.map &:pinged?
        exist_states = vm.ip_addresses.map &:exist_on_vm
        expect(ping_states + exist_states).to_not include false
      end

      it 'Allocate used IP' do
        skip
      end
    end

    describe 'Firewall rules' do
      after do
        vm.network_interface.reset_firewall_rules
        vm.update_firewall_rules
      end

      after :all do
        @vm.rebuild_network
      end

      it 'Set DROP default rule' do
        vm.network_interface.set_default_firewall_rule('DROP')
        vm.update_firewall_rules
        expect(vm.not_pinged?).to be true
      end

      it 'Set DROP rule for TCP custom port' do
        vm.network_interface.add_custom_firewall_rule(command: 'DROP')
        vm.update_firewall_rules
        expect(vm.port_closed?).to be true
      end

      it 'Set DROP rule for ICMP' do
        vm.network_interface.add_custom_firewall_rule(command: 'DROP', protocol: 'ICMP')
        vm.update_firewall_rules
        expect(vm.not_pinged?).to be true
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
        skip('Doest not work on gentoo') if @vm.operating_system_distro == 'gentoo'
        amount = vm.network_interface.amount
        vm.attach_network_interface
        expect(vm.port_opened?).to be true
        expect(vm.network_interface.amount).to eq amount + 1
      end

      it 'Detach' do
        skip('Doest not work on gentoo') if @vm.operating_system_distro == 'gentoo'
        amount = vm.network_interface.amount
        vm.network_interface('additional').remove
        expect(vm.port_opened?).to be true
        expect(vm.network_interface.amount).to eq amount - 1
      end

      it 'Detach primary network interface and attach again' do
        ip = vm.ip_address
        vm.network_interface.remove
        expect(vm.not_pinged?(remote_ip: ip)).to be true
        vm.attach_network_interface(primary: true)
        vm.network_interface.allocate_new_ip
        vm.rebuild_network
        expect(vm.pinged?).to be true
      end

      it 'Ability create two primary interfaces should be blocked' do
        skip
      end
    end
  end

  describe 'Boot from ISO' do
    before :all do
      @vsa.iso = Iso.new(@vsa)
      @is_folder_mounted = @vsa.hypervisor.is_data_mounted?
      @vsa.iso.create if @is_folder_mounted
      @iso_path = @vsa.settings.iso_path_on_hv
    end

    after :all do
      @vm.info_update.booted ? @vm.reboot : @vm.start_up
      @vsa.iso.remove if @is_folder_mounted
    end

    before { skip('The data folder isn\'t mounted on HV') unless @is_folder_mounted }

    let(:iso) { @vsa.iso }
    let(:hypervisor) { @vsa.hypervisor }

    it 'ISO file should exist on HV' do
      hypervisor.remount_data unless hypervisor.find_exist( @iso_path, iso.file_name)
      expect(hypervisor.find_exist(@iso_path, iso.file_name)).to be true
    end

    it 'Reboot VS from ISO' do
      skip('Virtual Server cannot be rebooted from this ISO') if !vm.can_be_booted_from_iso?(iso)
      vm.reboot_from_iso(iso.id)
      expect(vm.api_response_code).to eq '200'
      expect(vm.exist_on_hv?).to be true
    end

    it 'Boot VS from ISO' do
      skip('Virtual Server cannot be booted from this ISO') if !vm.can_be_booted_from_iso?(iso)
      vm.shut_down if vm.exist_on_hv?
      expect(vm.exist_on_hv?).to be false
      vm.boot_from_iso(iso.id)
      expect(vm.api_response_code).to eq '200'
      expect(vm.exist_on_hv?).to be true
    end

    context 'Negative' do
      it 'Reboot VS from ISO if not enough memory' do
        iso.edit(min_memory_size: vm.memory.to_i + 10)
        expect(vm.reboot_from_iso(iso.id)['error']).to eq("Virtual server must have at least #{iso.min_memory_size}MB of RAM")
        expect(vm.api_response_code).to eq '422'
        expect(vm.exist_on_hv?).to be true
      end

      it 'Reboot VS from ISO if incorrect virtualization type' do
        virt = vm.hypervisor_type == 'xen' ? 'kvm' : 'xen'
        iso.edit(virtualization: virt)
        expect(vm.reboot_from_iso(iso.id)['error']).to eq("Template virtualization is not compatible with compute resource type")
        expect(vm.api_response_code).to eq '422'
        expect(vm.exist_on_hv?).to be true
      end

      it 'Reboot VS from ISO if not enough disk space' do
        iso.edit(min_disk_size: vm.total_disk_size + 10)
        expect(vm.reboot_from_iso(iso.id)['error']).to eq("Virtual server primary disk size must be at least #{iso.min_disk_size}GB")
        expect(vm.api_response_code).to eq '422'
        expect(vm.exist_on_hv?).to be true
      end

      it 'Boot VS from ISO if not enough memory' do
        iso.edit(min_memory_size: vm.memory.to_i + 10)
        vm.shut_down if vm.exist_on_hv?
        expect(vm.exist_on_hv?).to be false
        expect(vm.boot_from_iso(iso.id)['error']).to eq("Virtual server must have at least #{iso.min_memory_size}MB of RAM")
        expect(vm.api_response_code).to eq '422'
        expect(vm.exist_on_hv?).to be false
      end

      it 'Boot VS from ISO if incorrect virtualization type' do
        virt = vm.hypervisor_type == 'xen' ? 'kvm' : 'xen'
        iso.edit(virtualization: virt)
        vm.shut_down if vm.exist_on_hv?
        expect(vm.exist_on_hv?).to be false
        expect(vm.boot_from_iso(iso.id)['error']).to eq("Template virtualization is not compatible with compute resource type")
        expect(vm.api_response_code).to eq '422'
        expect(vm.exist_on_hv?).to be false
      end

      it 'Boot VS from ISO if not enough disk space' do
        iso.edit(min_disk_size: vm.total_disk_size + 10)
        vm.shut_down if vm.exist_on_hv?
        expect(vm.exist_on_hv?).to be false
        expect(vm.boot_from_iso(iso.id)['error']).to eq("Virtual server primary disk size must be at least #{iso.min_disk_size}GB")
        expect(vm.api_response_code).to eq '422'
        expect(vm.exist_on_hv?).to be false
      end
    end
  end

  describe 'Backups' do
    before :all do
      @data_for_check = "File-#{SecureRandom.hex(4)}"
      @vm.port_opened?
      @vm.ssh_execute(">#{@data_for_check}")
      @vm.ssh_execute(SshCommands::OnVirtualServer.drop_caches)
    end

    let(:enable_incremental_autobackups) { SshCommands::OnControlPanel.enable_incremantal_autobackups }
    let(:enable_normal_autobackups)      { SshCommands::OnControlPanel.enable_normal_autobackups }
    let(:settings)                       { @vsa.settings }

    after :all do
      @vsa.settings.reset_to_primary if @vsa.settings.has_been_changed?
    end

    context 'Incremental backups allowed' do
      before :all do
        @backup = @vm.create_backup if @vsa.settings.allow_incremental_backups
      end

      before { skip('Incremental backups disabled') unless settings.allow_incremental_backups }

      let(:backup) { @backup }

      it 'backups should be visible in /files route' do
        ids = @vsa.get("#{vm.route}/backups/files").map { |b| b.backup.id }
        expect(ids).to include backup.id
      end

      it 'backup should not be visible in /images route' do
        ids = @vsa.get("#{vm.route}/backups/images").map { |b| b.backup.id }
        expect(ids).not_to include backup.id
      end

      it 'restore from backup' do
        vm.ssh_execute("rm -f #{@data_for_check}")
        expect(vm.ssh_execute('ls')).not_to include @data_for_check
        backup.restore
        expect(vm.port_opened?).to be true
        expect(vm.ssh_execute('ls')).to include @data_for_check
      end

      it 'convert to template and rebuild vm with it' do
        converted_template = backup.convert
        vm.rebuild(image: converted_template)
        expect(vm.port_opened?).to be true
        expect(@vm.ssh_execute('ls')).to include @data_for_check
        vm.rebuild(image: @template)
        @template.remove(converted_template.id)
      end

      it 'testing ability switch all VMs to normal autobackups', :settings_modified do
        vm.autobackup('enable')
        settings.setup(allow_incremental_backups: false)
        expect(@vsa.run_on_cp enable_normal_autobackups).to be true
        #TODO CORE-6634
        #expect(vm.info_update.support_incremental_backups).to be false
        expect(vm.wait_for_building_backups).to be true
        expect(vm.disk.has_autobackups).to be true
      end
    end

    context 'Normal backups allowed' do
      before :all do
        @backup = @vm.disk.create_backup unless @vsa.settings.allow_incremental_backups
      end

      before { skip('Normal backups disabled') if settings.allow_incremental_backups }

      let(:backup) { @backup }

      it 'backups should not be visible in /files route' do
        ids = @vsa.get("#{vm.route}/backups/files").map { |b| b.backup.id }
        expect(ids).not_to include backup.id
      end

      it 'backup should be visible in /images route' do
        ids = @vsa.get("#{vm.route}/backups/images").map { |b| b.backup.id }
        expect(ids).to include backup.id
      end

      it 'restore from backup' do
        vm.ssh_execute("rm -f #{@data_for_check}")
        expect(vm.ssh_execute('ls')).not_to include @data_for_check
        backup.restore
        expect(vm.port_opened?).to be true
        expect(vm.ssh_execute('ls')).to include @data_for_check
      end

      it 'convert to template and rebuild vm with it' do
        converted_template = backup.convert
        vm.rebuild(image: converted_template)
        expect(vm.port_opened?).to be true
        expect(@vm.ssh_execute('ls')).to include @data_for_check
        vm.rebuild(image: @template)
        @template.remove(converted_template.id)
      end

      it 'testing ability switch all VMs to incremental autobackups', :settings_modified do
        vm.disk.autobackup('enable')
        settings.setup(allow_incremental_backups: true)
        expect(@vsa.run_on_cp enable_incremental_autobackups).to be true
        expect(vm.info_update.support_incremental_backups).to be true
        expect(vm.wait_for_building_backups).to be true
        expect(vm.disk.has_autobackups).to be false
      end
    end
  end

  describe 'Recipes' do
    before(:all) do
      @recipe_group = Recipe::Group.new(@vsa).create
      @recipe_group.attach_recipe
      @recipe = @recipe_group.recipes.first
    end

    after(:all) do
      @recipe_group.recipes.map &:remove
      @recipe_group.remove
    end

    context 'have been joined and applied to vm_network_rebuild event' do
      before(:all) do
        @vm.join_recipe_to(@recipe.id, 'vm_network_rebuild')
        @vm.rebuild_network
        @vm.wait_for_run_recipes_on_server
      end

      it 'should be joined' do
        expect(@vsa.get("#{vm.route}/recipe_joins")).to have_key(:vm_network_rebuild)
      end

      it 'recipe should be applied' do
        expect(vm.ssh_execute('ls /root/')).to include @recipe.label
      end

      it 'env variables should be exported' do
        skip('IP address should be public') if vm.network_interface.ip_address.private?
        out = vm.ssh_execute('cat ' + @recipe.label, true)
        ips = vm.ip_addresses.map &:address
        expect(out & ips).not_to be_empty
        expect(out).to include vm.identifier
        expect(out).to include vm.ip_address
        expect(out).to include vm.hostname
        expect(out).to include vm.operating_system_distro
        expect(out).to include vm.initial_root_password
      end
    end
  end

  describe 'Autoscale', :autoscale do
    before do
      skip('Zabbix ip address is not available') unless  IPAddress.valid?(@vsa.settings.zabbix_host)
    end

    after :all do
      @vsa.settings.reset_to_primary if @vsa.settings.has_been_changed?
    end

    let(:zabbix_agent_status) { SshCommands::OnVirtualServer.zabbix_agent_status }

    it "zabbix agent should be enabled for #{ENV['TEMPLATE_MANAGER_ID']}" do
      expect(vm.port_opened?).to be true
      vm.autoscale_enable
      exit_status = vm.ssh_execute(zabbix_agent_status).last.to_i
      expect(exit_status.zero?).to be true
    end
  end
end