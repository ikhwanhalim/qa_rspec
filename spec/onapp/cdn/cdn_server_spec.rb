require 'spec_helper'
require './groups/cdn_server_actions'


describe 'Edge Server(STREAM)' do
  before :all do
    @vma = CdnServerActions.new.precondition
    @vm = @vma.virtual_machine
    @template = @vma.template
  end

  after :all do
    unless CdnServerActions::IDENTIFIER
      @vma.virtual_machine.destroy
    end
  end

  let(:vm) { @vma.virtual_machine }

  describe 'Power operations' do
    describe 'is  pinged?', :smoke do
      it { expect(vm.pinged?).to be true }

      it { expect(vm.exist_on_hv?).to be true }

      it { expect(vm.edge_server_type).to eq "streaming" }
    end

    it 'Stop' do
      vm.stop
      expect(vm.not_pinged?).to be true
    end

    it 'Start' do
      vm.start_up
      expect(vm.pinged? && vm.exist_on_hv?).to be true
    end

    it 'Shutdown' do
      vm.shut_down
      expect(vm.not_pinged?).to be true
    end

    it 'Startup' do
      vm.start_up
      expect(vm.pinged? && vm.exist_on_hv?).to be true
    end

    it 'Reboot' do
      vm.reboot
      expect(vm.pinged? && vm.exist_on_hv?).to be true
    end

    it 'Suspend and try startup(422)' do
      vm.suspend
      expect(vm.not_pinged?).to be true
      expect(vm.exist_on_hv?).to be false
      vm.start_up
      expect(vm.api_response_code).to eq '422'
    end

    it 'Unsuspend and Startup' do
      vm.unsuspend
      expect(vm.down?).to be true
      vm.start_up
      expect(vm.pinged? && vm.exist_on_hv?).to be true
    end

    it 'Reboot in recovery' do
      skip 'it is forbidden via UI, https://onappdev.atlassian.net/browse/CORE-8726'
      vm.reboot(recovery: true)
      expect(vm.port_opened?).to be true
      creds = {'es_host' => vm.ip_address, 'es_pass' => vm.initial_root_password}
      expect(vm.interface.execute_with_pass(creds, 'hostname')).to include 'recovery'
      vm.reboot
      expect(vm.pinged?).to be true
      expect(vm.port_opened?).to be true
    end
  end

  describe 'Perform disk action' do
    before :all do
      @disks_count_before_test = @vm.disks.count
    end

    def hot_actions_supported?
      @vma.hypervisor.distro != "centos5" && @vma.template.virtualization.include?('virtio') &&
          @vma.hypervisor.hypervisor_type == 'kvm'
    end

    it 'should not be added new(additional) disk' do
      expect(@vm.add_disk).to be nil
      expect(vm.api_response_code).to eq '422'
      expect(@vma.conn.page.body.errors.base).to eq ["New disk can not be added to EdgeServer"]
    end

    it 'primary disk size should be increased on virtual server' do
      new_disk_size = vm.disk.disk_size + 2
      vm.disk.edit(disk_size: new_disk_size)
      expect(vm.pinged? && vm.exist_on_hv?).to be true
      vm.info_update
      expect(vm.disk.disk_size).to eq new_disk_size
      # expect(vm.disk_size_compare_with_interface_lvscan(swap_identifier)).to eq new_swap_disk_size
    end

    it 'primary disk size should be decreased on virtual server' do
      new_disk_size = vm.disk.disk_size - 1
      vm.disk.edit(disk_size: new_disk_size)
      expect(vm.pinged? && vm.exist_on_hv?).to be true
      vm.info_update
      expect(vm.disk.disk_size).to eq new_disk_size
      # expect(vm.disk_size_compare_with_interface_lvscan(swap_identifier)).to eq new_swap_disk_size
    end

    it 'should be impossible to add second primary disk with template min_disk_size to VS' do
      vm.add_disk(primary: true, primary_disk_size: vm.template.min_disk_size)
      expect(vm.api_response_code).to eq '422'
    end

    it 'should be impossible to add second primary disk with minimal available size to VS' do
      vm.add_disk(primary: true)
      expect(vm.api_response_code).to eq '422'
    end

    it 'should be possible increase size of swap disk' do
      skip "the swap disk is forbidden in UI"
      new_swap_disk_size=vm.disk('swap').disk_size + 2
      vm.disk('swap').edit(disk_size: new_swap_disk_size)
      expect(vm.pinged? && vm.exist_on_hv?).to be true
      # swap_identifier = vm.disk('swap').identifier
      #TODO expect(vm.disk_size_compare_with_interface_lvscan(swap_identifier)).to eq new_swap_disk_size
      vm.info_update
      expect(vm.disk('swap').disk_size).to eq new_swap_disk_size
    end

    it 'should be possible decrease size of swap disk' do
      skip "the swap disk is forbidden in UI"
      new_swap_disk_size=vm.disk('swap').disk_size - 1
      vm.disk('swap').edit(disk_size: new_swap_disk_size)
      expect(vm.pinged? && vm.exist_on_hv?).to be true
      vm.info_update
      expect(vm.disk('swap').disk_size).to eq new_swap_disk_size
    end

    it 'primary disk should be migrated if there is available DS on a cloud' do
      datastore_id = vm.disk.available_data_store_for_migration
      if datastore_id
        vm.disk.migrate(datastore_id)
        expect(vm.disk.data_store_id).to eq datastore_id
      else
        skip("skipped because we have not found available data stores for migration.")
      end
    end

    #TODO increase disk size during unlocking
  end

  describe 'Network' do
    it 'rebuild' do
      expect(@vm.rebuild_network).to be true
      expect(vm.pinged? && vm.exist_on_hv?).to be true
    end
  end

  describe 'Rerun edge srcipts' do
    it 'rerun' do
      unless vm.edge_status == 'Inactive' || vm.edge_status == 'Active'
        expect(vm.rerun_cdn_scripts).to eq true
      else
        Log.info("ES(stream): edge_status = ACTIVE")
      end
    end
  end

  describe 'Notes' do
    context 'Admin' do
      it 'should be created' do
        vm.add_note(admin_note: "ad-qa_ant_admin_note")
        expect(vm.admin_note).to eq "ad-qa_ant_admin_note"
      end

      it 'should be edited' do
        vm.add_note(admin_note: "ad-qa_ant_admin_note-edited")
        expect(vm.admin_note).to eq "ad-qa_ant_admin_note-edited"
      end

      it 'should be deleted' do
        vm.destroy_note("admin_note")
        expect(vm.admin_note).to be nil
      end
    end

    context 'User' do
      it 'should be created' do
        vm.add_note(note: "ad-qa_ant_user_note")
        expect(vm.note).to eq "ad-qa_ant_user_note"
      end

      it 'should be edited' do
        vm.add_note(note: "ad-qa_ant_user_note")
        expect(vm.note).to eq "ad-qa_ant_user_note"
      end

      it 'should be deleted' do
        vm.destroy_note("note")
        expect(vm.note).to be nil
      end
    end
  end

  describe 'Edit' do
    it 'RAM' do
      new_ram = vm.memory.to_i + 10
      vm.edit(memory: new_ram)
      expect(vm.memory).to eq new_ram
    end

    it 'CPU' do
      new_cpus = vm.cpus + 1
      vm.edit_cpus(cpus: new_cpus)
      expect(vm.cpus).to eq new_cpus
    end

    it 'Label' do
      new_label = "#{vm.label}-edit"
      vm.edit(label: new_label)
      expect(vm.label).to eq new_label
    end

    it 'market place' do
      status = vm.add_to_marketplace
      vm.edit_market_place_status
      if status == false
        expect(vm.add_to_marketplace).to eq true
      else
        expect(vm.add_to_marketplace).to eq false
      end
    end

    it 'set vip' do
      skip "https://onappdev.atlassian.net/browse/CORE-8814"
      if vm.vip == (nil || false)
        vm.set_vip({vip: "true"})
        expect(vm.vip).to eq true
      else
        vm.set_vip({vip: "false"})
        expect(vm.vip).to eq false
      end
    end
  end
end
