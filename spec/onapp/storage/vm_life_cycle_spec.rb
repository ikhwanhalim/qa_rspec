require 'spec_helper'
require './groups/virtual_server_actions'

describe 'Virtual Server actions tests' do
  before :all do
    @vsa = VirtualServerActions.new.precondition
    @vm = @vsa.virtual_machine
    @template = @vsa.template
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

    it 'primary disk size should be increased on virtual server' do
      new_disk_size = vm.disk.disk_size + 2
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

    it 'primary disk should be migrated if there is available DS on a cloud' do
      if vm.disk.available_data_store_for_migration
        vm.disk.migrate
        expect(vm.port_opened?).to be true
      else
        skip("skipped because we have not found available data stores for migration.")
      end
    end

    it 'additional disk should be migrated if there is additional DS' do
      if @disk.available_data_store_for_migration
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
end