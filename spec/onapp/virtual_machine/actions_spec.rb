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

  # FOR DEBUG
  # after do
  #   require 'pry';binding.pry if example.exception
  # end

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
      additiona_swap_disk = vm.add_disk(is_swap: true, disk_size: 2)
      additiona_swap_disk.wait_for_build
      expect(vm.port_opened?).to be true
      expect(vm.disk('swap').disk_size_compare_with_interface).to eq false #this can be refactored to determine each swap disk separately
      additiona_swap_disk.remove
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

    it 'additional disk should be hot attached/detached' do
      skip('Hot actions not supported') unless hot_actions_supported?
      expect(vm.pinged?).to be true
      disk = vm.add_disk(hot_attach: 1)
      disk.wait_for_attach
      expect(disk.disk_size_compare_with_interface).to be true
      disk.detach
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
      after do
        vm.network_interface.reset_firewall_rules
        vm.network_interface.set_default_firewall_rule
        vm.update_firewall_rules
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
        expect(vm.network_interface.amount).to eq amount + 1
      end

      it 'Detach' do
        skip('Doest not work on gentoo') if @vm.operating_system_distro == 'gentoo'
        amount = vm.network_interface.amount
        vm.network_interface('additional').remove
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

  describe 'Reboot in recovery operation' do
    it 'Reboot in recovery Operations' do
      skip('Could not connect to private ip') if vm.network_interface.ip_address.private?
      vm.reboot(recovery: true)
      expect(vm.port_opened?).to be true
      creds = {'vm_host' => vm.ip_address, 'vm_pass' => vm.initial_root_password}
      expect(vm.interface.execute_with_pass(creds, 'hostname')).to include 'recovery'
      vm.reboot
      expect(vm.port_opened?).to be true
      expect(vm.ssh_execute('hostname').join(' ')).to match vm.hostname
    end
  end

#Reboot VS from ISO
  describe 'ISO' do
    before :all do
      @vsa.iso = Iso.new(@vsa)
      @is_folder_mounted = @vsa.hypervisor.is_data_mounted?
      @vsa.iso.create if @is_folder_mounted
    end

    after :all do
      @vm.reboot
      @vsa.iso.remove if @is_folder_mounted
    end

    before { skip('The data folder isn\'t mounted on HV') unless @is_folder_mounted }

    let(:iso) { @vsa.iso }
    let(:hypervisor) { @vsa.hypervisor }

    it 'ISO file should exist on HV' do
      hypervisor.remount_data unless hypervisor.find_exist('/data', iso.file_name)
      expect(hypervisor.find_exist('/data', iso.file_name)).to be true
    end

    it 'Reboot VS from ISO' do
      skip('Virtual Server cannot be rebooted from this ISO') if !vm.can_be_booted_from_iso?
      vm.reboot_from_iso(iso.id)
      expect(vm.api_response_code).to eq '200'
      expect(vm.exist_on_hv?).to be true
    end

    it 'Reboot VS from ISO if not enough memory' do
      iso.edit(min_memory_size: vm.memory.to_i + 10,
               min_disk_size: vm.total_disk_size - 1)
      vm.reboot_from_iso(iso.id)
      expect(vm.api_response_code).to eq '422'
      expect(vm.exist_on_hv?).to be true
    end

    it 'Reboot VS from ISO if incorrect virtualization type' do
      skip("https://onappdev.atlassian.net/browse/CORE-5721")
      vm.hypervisor_type == 'xen' ? iso.edit(virtualization: 'kvm', min_memory_size: vm.memory.to_i, min_disk_size: vm.total_disk_size - 1) : iso.edit(virtualization: 'xen', min_memory_size: vm.memory.to_i, min_disk_size: vm.total_disk_size - 1)
      vm.reboot_from_iso(iso.id)
      expect(vm.api_response_code).to eq '422'
      expect(vm.exist_on_hv?).to be true
    end

    it 'Reboot VS from ISO if not enough disk space' do
      iso.edit(min_disk_size: vm.total_disk_size + 10,
               min_memory_size: vm.memory.to_i)
      vm.reboot_from_iso(iso.id)
      expect(vm.api_response_code).to eq '422'
      expect(vm.exist_on_hv?).to be true
    end

    it 'Boot VS from ISO' do
      skip('Virtual Server cannot be booted from this ISO') if !vm.can_be_booted_from_iso?
      vm.shut_down if vm.exist_on_hv?
      expect(vm.exist_on_hv?).to be false
      vm.boot_from_iso(iso.id)
      expect(vm.api_response_code).to eq '200'
      expect(vm.exist_on_hv?).to be true
    end

    it 'Boot VS from ISO if not enough memory' do
      iso.edit(min_memory_size: vm.memory.to_i + 10,
              min_disk_size: vm.total_disk_size - 1)
      vm.shut_down if vm.exist_on_hv?
      expect(vm.exist_on_hv?).to be false
      vm.boot_from_iso(iso.id)
      expect(vm.api_response_code).to eq '422'
      expect(vm.exist_on_hv?).to be false
    end

    it 'Boot VS from ISO if incorrect virtualization type' do
      skip("https://onappdev.atlassian.net/browse/CORE-5721")
      vm.hypervisor_type == 'xen' ? iso.edit(virtualization: 'kvm', min_memory_size: vm.memory.to_i, min_disk_size: vm.total_disk_size - 1) : iso.edit(virtualization: 'xen', min_memory_size: vm.memory.to_i, min_disk_size: vm.total_disk_size - 1)
      vm.shut_down if vm.exist_on_hv?
      expect(vm.exist_on_hv?).to be false
      vm.boot_from_iso(iso.id)
      expect(vm.api_response_code).to eq '422'
      expect(vm.exist_on_hv?).to be false
    end

    it 'Boot VS from ISO if not enough disk space' do
      iso.edit(min_disk_size: vm.total_disk_size + 10,
               min_memory_size: vm.memory.to_i)
      vm.shut_down if vm.exist_on_hv?
      expect(vm.exist_on_hv?).to be false
      vm.boot_from_iso(iso.id)
      expect(vm.api_response_code).to eq '422'
      expect(vm.exist_on_hv?).to be false
    end
  end

  describe 'Backups' do
    let(:enable_incremental_autobackups) { SshCommands::OnControlPanel.enable_incremantal_autobackups }
    let(:enable_normal_autobackups)      { SshCommands::OnControlPanel.enable_normal_autobackups }
    let(:settings)                       { @vsa.settings }

    after :all do
      @vsa.settings.reset_to_primary
    end

    context 'Incremental backups allowed' do
      before { skip('Incremental backups disabled') unless settings.allow_incremental_backups }

      it 'testing ability switch all VMs to normal autobackups' do
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
      before { skip('Normal backups disabled') if settings.allow_incremental_backups }

      it 'testing ability switch all VMs to incremental autobackups' do
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
      end

      it 'should be joined' do
        expect(@vsa.get("#{vm.route}/recipe_joins")).to have_key(:vm_network_rebuild)
      end

      it 'transaction should be successfully complited' do
        expect(vm.wait_for_run_recipes_on_server).to be true
      end

      it 'recipe should be applied' do
        expect(vm.ssh_execute('ls /root/')).to include @recipe.label
      end

      it 'env variables should be exported' do
        out = vm.ssh_execute('cat /root/' + @recipe.label)
        expect(out).to include vm.identifier
        expect(out).to include vm.ip_address
        expect(out).to include vm.hostname
        expect(out).to include vm.operating_system_distro
        expect(out).to include vm.initial_root_password
      end
    end
  end
end