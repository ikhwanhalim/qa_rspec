require 'spec_helper'
require './groups/cdn_server_actions'
require './spec/onapp/cdn/shared_examples/cdn_server'


describe "Main tests: #{CdnServer::CDN_SERVER} -->" do
  before :all do
    @vma = CdnServerActions.new.precondition
    @cp_version = @vma.version
    @vm = @vma.virtual_machine
    @template = @vma.template
  end

  after :all do
    unless CdnServerActions::IDENTIFIER
      @vma.virtual_machine.destroy
    end
  end

  let(:vm) { @vma.virtual_machine }

  describe 'Power operations ->' do
    include_examples  'power_operations'
  end

  describe 'Perform disk action ->' do
    before :all do
      @disks_count_before_test = @vm.disks.count
    end

    include_examples 'disk_actions'
  end

  describe 'Network ->' do
    include_examples 'firewall'
    include_examples 'ip_addresses'

    context 'network_interface ->' do
      include_examples 'network_interfaces'

      it 'Attach extra NIC' do
        amount = vm.network_interfaces.count
        vm.attach_network_interface
        expect(@vma.conn.page.code).to eq '422'
        expect(@vma.conn.page.body.errors.network).to eq ["Only one Network allowed per Accelerator"]
        expect(vm.network_interfaces.count).to eq amount
      end
    end
  end

  describe 'Rerun edge srcipts ->' do
    include_examples 'rerun_edge_srcipt'
  end

  describe 'Notes ->' do
    include_examples 'notes'
  end

  describe 'Edit ->' do
    include_examples 'edit'

    it 'market place' do
      expect(vm.add_to_marketplace).to eq nil
    end
  end
end
