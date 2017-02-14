require 'spec_helper'
require './groups/storage_actions'
require './groups/virtual_server_actions'

# Based on 2r2s datastore raid type
# 2HVs, 3 members per each are minimum requirements
# for some cases DM-CACHE should be enabled and configured

describe 'Autohealing =>' do
  before :all do
    @sda = StorageActions.new.precondition
    @hypervisor = @sda.hypervisor
    @vdisk = { create: -> { StorageActions.new.precondition.storage_disk.create } }
    @high_utilised_vdisk = { create: -> { StorageActions.new.precondition.storage_disk.create_high_utilised_vdisk } }
    @max_vdisk = { create: -> { StorageActions.new.precondition.storage_disk.create_max_vdisk } }
  end

  let (:sda)                {@sda}
  let (:enable_autohealing) { SshCommands::OnControlPanel.run_autohealing_task }

  context 'The diagnostic requirements met autohealing DISABLED =>' do

    before :all do
      @storage_disk = @vdisk[:create].()
      @storage_disk.edit_is_datastore(0, 0)
    end

    let (:storage_disk) { @storage_disk }

    it 'should have datastore autohealing disabled' do
      expect(storage_disk.get_datastore_autohealing?).to be false
    end

    it 'should have vdisk degraded' do
      expect(storage_disk.make_degraded).to be true
    end

    it 'should not repair degraded vdisk' do
      storage_disk.get_repair_parent_id
      sda.run_on_cp(enable_autohealing)
      expect { storage_disk.repair_transaction_wait }.
          to raise_error(RuntimeError)
    end

    after :all do
      @storage_disk.destroy_all_vdisks
    end
  end

  context 'The diagnostic requirements met autohealing ENABLED =>' do

    before :all do
      @storage_disk = @vdisk[:create].()
      @storage_disk.edit_is_datastore
    end

    let (:storage_disk) { @storage_disk }

    it 'should have datastore autohealing enabled' do
      expect(storage_disk.get_datastore_autohealing?).to be true
    end

    it 'should have vdisk degraded' do
      expect(storage_disk.make_degraded).to be true
    end

    it 'should repair all degraded vdisks one by one' do
      storage_disk.get_last_repair_delivery
      storage_disk.get_repair_parent_id
      sda.run_on_cp(enable_autohealing)
      expect(storage_disk.repair_transaction_wait).to be true
    end

    it 'should send email to a customer about repairing' do
      expect(storage_disk.repair_delivery_sent?).to be true
    end

    after :all do
      @storage_disk.destroy_all_vdisks
    end
  end

  context 'The diagnostic requirements do not meet: partial memberlist =>' do

    before :all do
      @partial_disk = @vdisk[:create].()
      @degraded_disk = @vdisk[:create].()
    end

    let(:partial_disk)  { @partial_disk }
    let(:degraded_disk) { @degraded_disk }

    it 'should have datastore autohealing enabled' do
      expect(partial_disk.get_datastore_autohealing?).to be true
    end

    it 'should have vdisk with partial memberlist' do
      expect(partial_disk.make_partial_memberlist(partial_disk.id)).to be true
    end

    it 'should have vdisk degraded' do
      expect(degraded_disk.make_degraded).to be true
    end

    it 'should not repair degraded vdisks' do
      degraded_disk.get_last_failed_diagnostic_delivery
      degraded_disk.get_repair_parent_id
      sda.run_on_cp(enable_autohealing)
      expect { degraded_disk.repair_transaction_wait }.
          to raise_error(RuntimeError)
    end

    it 'should send email about failed diagnostic requirements to a customer' do
      expect(degraded_disk.repair_failed_diagnostic_sent?).to be true
    end

    after :all do
      @degraded_disk.destroy_all_vdisks
    end
  end

  context 'The diagnostic requirements do not meet: vdisk with no redundancy =>' do

    before :all do
      @no_redundant_disk = @vdisk[:create].()
      @degraded_disk = @vdisk[:create].()
      @sda.settings.setup(enforce_redundancy: false)
      sleep(360)
    end

    let(:no_redundant_disk) { @no_redundant_disk }
    let(:degraded_disk)     { @degraded_disk }

    it 'should have datastore autohealing enabled' do
      expect(degraded_disk.get_datastore_autohealing?).to be true
    end

    it 'should perform vdisk rebalance transaction' do
      no_redundant_disk.get_repair_parent_id
      no_redundant_disk.rebalance_vdisk(no_redundant_disk.id)
      expect(no_redundant_disk.rebalance_transaction_wait).to be true
    end

    it 'should have vdisk with no redundancy' do
      expect(no_redundant_disk.get_no_redundant_vdisk).to be true
    end

    it 'should have vdisk degraded' do
      expect(degraded_disk.make_vdisk_degraded(degraded_disk.id)).to be true
    end

    it 'should not repair degraded vdisks' do
      degraded_disk.get_last_failed_diagnostic_delivery
      degraded_disk.get_repair_parent_id
      sda.run_on_cp(enable_autohealing)
      expect {degraded_disk.repair_transaction_wait}.
          to raise_error(RuntimeError)
    end

    it 'should send email about failed diagnostic requirements to a customer' do
      expect(degraded_disk.repair_failed_diagnostic_sent?).to be true
    end

    after :all do
      @degraded_disk.destroy_all_vdisks
      @sda.settings.reset_to_primary
      sleep(360)
    end
  end

  context 'The diagnostic requirements do not meet: partially online vdisk =>' do

    before :all do
      @degraded_disk = @vdisk[:create].()
      @partially_online_disk = @vdisk[:create].()
    end

    let(:degraded_disk)          { @degraded_disk }
    let(:partially_online_disk)  { @partially_online_disk }

    it 'should have datastore autohealing enabled' do
      expect(degraded_disk.get_datastore_autohealing?).to be true
    end

    it 'should have vdisk with partially online state' do
      expect(partially_online_disk.make_partially_online(partially_online_disk.id)).to be true
    end

    it 'should have vdisk degraded' do
      expect(degraded_disk.make_vdisk_degraded(degraded_disk.id)).to be true
    end

    it 'should not repair degraded vdisk' do
      degraded_disk.get_last_failed_diagnostic_delivery
      degraded_disk.get_repair_parent_id
      sda.run_on_cp(enable_autohealing)
      expect {degraded_disk.repair_transaction_wait}.
          to raise_error(RuntimeError)
    end

    it 'should send email about failed diagnostic requirements to a customer' do
      expect(degraded_disk.repair_failed_diagnostic_sent?).to be true
    end

    after :all do
      @degraded_disk.destroy_all_vdisks
    end
  end

  context 'The diagnostic requirements do not meet: other degraded state vdisk =>' do

    before :all do
      @degraded_disk = @vdisk[:create].()
      @other_degraded_disk = @vdisk[:create].()
    end

    let(:degraded_disk)          { @degraded_disk }
    let(:other_degraded_disk)    { @other_degraded_disk }

    it 'should have datastore autohealing enabled' do
      expect(degraded_disk.get_datastore_autohealing?).to be true
    end

    it 'should have vdisk in other degraded state' do
      expect(other_degraded_disk.make_other_degraded_state(other_degraded_disk.id)).to be true
    end

    it 'should have vdisk degraded' do
      expect(degraded_disk.make_vdisk_degraded(degraded_disk.id)).to be true
    end

    it 'should not repair degraded vdisks' do
      degraded_disk.get_last_failed_diagnostic_delivery
      degraded_disk.get_repair_parent_id
      sda.run_on_cp(enable_autohealing)
      expect {degraded_disk.repair_transaction_wait}.
          to raise_error(RuntimeError)
    end

    it 'should send email about failed diagnostic requirements to a customer' do
      expect(degraded_disk.repair_failed_diagnostic_sent?).to be true
    end

    after :all do
      @degraded_disk.destroy_all_vdisks
    end
  end

  context 'The diagnostic requirements do not meet: partial nodes found =>' do

    before :all do
      @degraded_disk = @vdisk[:create].()
    end

    let(:degraded_disk) { @degraded_disk }


    it 'should have datastore autohealing enabled' do
      expect(degraded_disk.get_datastore_autohealing?).to be true
    end

    it 'should have vdisk degraded' do
      expect(degraded_disk.make_vdisk_degraded(degraded_disk.id)).to be true
    end

    it 'should have partial nodes found' do
      expect(degraded_disk.make_partial_nodes)
    end

    it 'should not repair degraded vdisks' do
      degraded_disk.get_last_failed_diagnostic_delivery
      degraded_disk.get_repair_parent_id
      sda.run_on_cp(enable_autohealing)
      expect {degraded_disk.repair_transaction_wait}.
          to raise_error(RuntimeError)
    end

    it 'should send email about failed diagnostic requirements to a customer' do
      expect(degraded_disk.repair_failed_diagnostic_sent?).to be true
    end

    it 'should repair all partial nodes' do
      node = degraded_disk.get_partial_node_to_repair(degraded_disk.id)
      degraded_disk.repair_partial_node(node)
      expect(degraded_disk.node_repaired?).to be true
    end

    after :all do
      @degraded_disk.destroy_all_vdisks
    end
  end

  context 'The diagnostic requirements do not meet: inactive nodes found =>' do

    before :all do
      @degraded_disk = @vdisk[:create].()
    end

    let(:degraded_disk) { @degraded_disk }

    it 'should have datastore autohealing enabled' do
      expect(degraded_disk.get_datastore_autohealing?).to be true
    end

    it 'should have vdisk degraded' do
      expect(degraded_disk.make_vdisk_degraded(degraded_disk.id)).to be true
    end

    it 'should have inactive nodes found' do
      expect(degraded_disk.make_inactive_nodes).to be true
    end

    it 'should not repair degraded vdisks' do
      degraded_disk.get_last_failed_diagnostic_delivery
      degraded_disk.get_repair_parent_id
      sda.run_on_cp(enable_autohealing)
      expect {degraded_disk.repair_transaction_wait}.
          to raise_error(RuntimeError)
    end

    it 'should send email about failed diagnostic requirements to a customer' do
      expect(degraded_disk.repair_failed_diagnostic_sent?).to be true
    end

    it 'should repair all inactive nodes' do
      expect(degraded_disk.node_activated?).to be true
    end

    after :all do
      @degraded_disk.destroy_all_vdisks
    end
  end

  context 'The diagnostic requirements do not meet: delayed ping nodes found =>' do

    before :all do
      @degraded_disk = @vdisk[:create].()
    end

    let(:degraded_disk) { @degraded_disk }


    it 'should have datastore autohealing enabled' do
      expect(degraded_disk.get_datastore_autohealing?).to be true
    end

    it 'should have vdisk degraded' do
      expect(degraded_disk.make_vdisk_degraded(degraded_disk.id)).to be true
    end

    it 'should have delayed ping nodes found' do
      expect(degraded_disk.make_nodes_with_delayed_ping).to be true
    end

    it 'should not repair degraded vdisks' do
      degraded_disk.get_last_failed_diagnostic_delivery
      degraded_disk.get_repair_parent_id
      sda.run_on_cp(enable_autohealing)
      expect {degraded_disk.repair_transaction_wait}.
          to raise_error(RuntimeError)
    end

    it 'should send email about failed diagnostic requirements to a customer' do
      expect(degraded_disk.repair_failed_diagnostic_sent?).to be true
    end

    it 'should repair all nodes with delayed ping' do
      expect(degraded_disk.delayed_ping_nodes_repaired?).to be true
    end

    after :all do
      @degraded_disk.destroy_all_vdisks
    end
  end

  context 'The diagnostic requirements do not meet: node with high utilisation found =>' do

    before :all do
      @degraded_disk = @vdisk[:create].()
      @utilised_vdisk = @high_utilised_vdisk[:create].()
    end

    let(:degraded_disk) { @degraded_disk }
    let(:utilised_vdisk) { @utilised_vdisk }


    it 'should have datastore autohealing enabled' do
      expect(degraded_disk.get_datastore_autohealing?).to be true
    end

    it 'should have vdisk degraded' do
      expect(degraded_disk.make_vdisk_degraded(degraded_disk.id)).to be true
    end

    it 'should have high utilisation node found' do
      expect(utilised_vdisk.make_nodes_with_high_utilisation(utilised_vdisk.id)).to be true
      expect(utilised_vdisk.get_nodes_with_high_utilisation).to be true
    end

    it 'should not repair degraded vdisks' do
      degraded_disk.get_last_failed_diagnostic_delivery
      degraded_disk.get_repair_parent_id
      sda.run_on_cp(enable_autohealing)
      expect {degraded_disk.repair_transaction_wait}.
          to raise_error(RuntimeError)
    end

    it 'should send email about failed diagnostic requirements to a customer' do
      expect(degraded_disk.repair_failed_diagnostic_sent?).to be true
    end

    after :all do
      @degraded_disk.destroy_all_vdisks
    end
  end

  context 'The diagnostic requirements do not meet: out of space node found =>' do

    before :all do
      @degraded_disk = @vdisk[:create].()
      @disk_set = []
      loop do
        @disk_set << @max_vdisk[:create].()
        break if @degraded_disk.max_vdisk_size == "0"
      end
    end

    let(:degraded_disk) { @degraded_disk }
    let(:disk_set) { @disk_set }


    it 'should have datastore autohealing enabled' do
      expect(degraded_disk.get_datastore_autohealing?).to be true
    end

    it 'should have vdisk degraded' do
      degraded_disk.make_out_of_space_nodes(degraded_disk.id)
      expect(degraded_disk.make_vdisk_degraded(degraded_disk.id)).to be true
    end

    it 'should have out of space node found' do
      disk_set[0].make_out_of_space_nodes(disk_set[0].id)
      expect(disk_set[0].get_nodes_with_high_utilisation).to be true
    end

    it 'should not repair degraded vdisks' do
      degraded_disk.get_last_failed_diagnostic_delivery
      degraded_disk.get_repair_parent_id
      sda.run_on_cp(enable_autohealing)
      expect {degraded_disk.repair_transaction_wait}.
          to raise_error(RuntimeError)
    end

    it 'should send email about failed diagnostic requirements to a customer' do
      expect(degraded_disk.repair_failed_diagnostic_sent?).to be true
    end

    after :all do
      @degraded_disk.destroy_all_vdisks
    end
  end

  context 'The diagnostic requirements do not meet: inactive controllers found =>' do

    before :all do
      @degraded_disk = @vdisk[:create].()
    end

    let(:degraded_disk) { @degraded_disk }


    it 'should have datastore autohealing enabled' do
      expect(degraded_disk.get_datastore_autohealing?).to be true
    end

    it 'should have vdisk degraded' do
      expect(degraded_disk.make_vdisk_degraded(degraded_disk.id)).to be true
    end

    it 'should have inactive controllers' do
      expect(degraded_disk.make_inactive_controllers).to be true
    end

    it 'should not repair degraded vdisks' do
      degraded_disk.get_last_failed_diagnostic_delivery
      degraded_disk.get_repair_parent_id
      sda.run_on_cp(enable_autohealing)
      expect {degraded_disk.repair_transaction_wait}.
          to raise_error(RuntimeError)
    end

    it 'should send email about failed diagnostic requirements to a customer' do
      expect(degraded_disk.repair_failed_diagnostic_sent?).to be true
    end

    it 'should repair all inactive controllers' do
      expect(degraded_disk.inactive_controllers_repair?).to be true
    end

    after :all do
      sleep(180)
      @degraded_disk.destroy_all_vdisks
    end
  end

  context 'The diagnostic requirements do not meet: unreferenced nbds found =>' do

    before :all do
      @degraded_disk = @vdisk[:create].()
      @unreferenced_nbds_disk = @vdisk[:create].()
    end

    let(:degraded_disk)          { @degraded_disk }
    let(:unreferenced_nbds_disk)  { @unreferenced_nbds_disk }

    it 'should have datastore autohealing enabled' do
      expect(degraded_disk.get_datastore_autohealing?).to be true
    end

    it 'should have vdisk with unreferenced nbds' do
      expect(unreferenced_nbds_disk.make_unreferenced_nbds(unreferenced_nbds_disk.id)).to be true
    end

    it 'should have vdisk degraded' do
      expect(degraded_disk.make_vdisk_degraded(degraded_disk.id)).to be true
    end

    it 'should not repair degraded vdisks' do
      degraded_disk.get_last_failed_diagnostic_delivery
      degraded_disk.get_repair_parent_id
      sda.run_on_cp(enable_autohealing)
      expect {degraded_disk.repair_transaction_wait}.
          to raise_error(RuntimeError)
    end

    it 'should send email about failed diagnostic requirements to a customer' do
      expect(degraded_disk.repair_failed_diagnostic_sent?).to be true
    end

    after :all do
      @unreferenced_nbds_disk.repair_unreferenced_nbds
      @degraded_disk.destroy_all_vdisks
    end
  end

  # context 'The diagnostic requirements do not meet: reused NBDs found =>' do
  #
  #   before :all do
  #     @degraded_disk = @vdisk[:create].()
  #     @reused_nbds_disk = @vdisk[:create].()
  #   end
  #
  #   let(:degraded_disk)     { @degraded_disk }
  #   let(:reused_nbds_disk)  { @reused_nbds_disk }
  #
  #   it 'should have datastore autohealing enabled' do
  #     expect(degraded_disk.get_datastore_autohealing?).to be true
  #   end
  #
  #   it 'should have vdisk with reused NBDs' do
  #     expect(reused_nbds_disk.make_reused_nbds(reused_nbds_disk.id)).to be true
  #   end
  #
  #   it 'should have vdisk degraded' do
  #     expect(degraded_disk.make_vdisk_degraded(degraded_disk.id)).to be true
  #   end
  #
  #   it 'should not repair degraded vdisks' do
  #     degraded_disk.get_last_failed_diagnostic_delivery
  #     degraded_disk.get_repair_parent_id
  #     sda.run_on_cp(enable_autohealing)
  #     expect {degraded_disk.repair_transaction_wait}.
  #         to raise_error(RuntimeError, "Unable to find transaction according to credentials")
  #   end
  #
  #   it 'should send email about failed diagnostic requirements to a customer' do
  #     expect(degraded_disk.repair_failed_diagnostic_sent?).to be true
  #   end
  #
  #   after :all do
  #     @reused_nbds_disk.repair_reused_nbds
  #     @degraded_disk.destroy_all_vdisks
  #   end
  # end

  context 'The diagnostic requirements do not meet: disks with inactive cache found =>' do

    before :all do
      @degraded_disk = @vdisk[:create].()
      @degraded_disk.edit_is_datastore
      @vsa = VirtualServerActions.new.precondition
      @vm = @vsa.virtual_machine
      @template = @vsa.template
    end

    let(:degraded_disk) { @degraded_disk }
    let(:vm)            { @vm }

    it 'should have datastore autohealing enabled' do
      expect(degraded_disk.get_datastore_autohealing?).to be true
    end

    it 'should have vdisk with inactive cache found' do
      expect(degraded_disk.
          make_inactive_cache(1, 1)).to be true
    end

    it 'should have vdisk degraded' do
      expect(degraded_disk.make_vdisk_degraded(degraded_disk.id)).to be true
    end

    it 'should not repair degraded vdisks' do
      degraded_disk.get_last_failed_diagnostic_delivery
      degraded_disk.get_repair_parent_id
      sda.run_on_cp(enable_autohealing)
      expect {degraded_disk.repair_transaction_wait}.
          to raise_error(RuntimeError)
    end

    it 'should send email about failed diagnostic requirements to a customer' do
      expect(degraded_disk.repair_failed_diagnostic_sent?).to be true
    end

    after :all do
      @degraded_disk.destroy_all_vdisks
      unless VirtualServerActions::IDENTIFIER
        @vm.destroy
        @template.remove if @vm.find_by_template(@template.id).empty?
      end
    end
  end

  context 'The diagnostic requirements do not meet: stale cache volumes found =>' do

    before :all do
      @degraded_disk = @vdisk[:create].()
      @stale_cache_volumes_disk = @vdisk[:create].()
    end

    let(:degraded_disk)             { @degraded_disk }
    let(:stale_cache_volumes_disk)  { @stale_cache_volumes_disk }

    it 'should have datastore autohealing enabled' do
      expect(degraded_disk.get_datastore_autohealing?).to be true
    end

    it 'should have vdisk with stale cache volumes found' do
      expect(stale_cache_volumes_disk.
          make_stale_cache_volumes(stale_cache_volumes_disk.id)).to be true
    end

    it 'should have vdisk degraded' do
      expect(degraded_disk.make_vdisk_degraded(degraded_disk.id)).to be true
    end

    it 'should not repair degraded vdisks' do
      degraded_disk.get_last_failed_diagnostic_delivery
      degraded_disk.get_repair_parent_id
      sda.run_on_cp(enable_autohealing)
      expect {degraded_disk.repair_transaction_wait}.
          to raise_error(RuntimeError)
    end

    it 'should send email about failed diagnostic requirements to a customer' do
      expect(degraded_disk.repair_failed_diagnostic_sent?).to be true
    end

    after :all do
      @stale_cache_volumes_disk.repair_stale_cache_volumes
      @degraded_disk.destroy_all_vdisks
    end
  end
end

# TODO:
# 1. understand how to get reused NBDs found, finish spec
# 2. figure out how to get inactive cache volumes state
#     or ask for a storageAPI call, finish method: "make inactive cache found in the diagnostic module"
# 3. come up with idea how to get out of space node in proper way,
#     now it is unstable. 99% utilisation in 50% of cases.




