require 'spec_helper'
require './groups/cdn_server_actions'
require './spec/onapp/cdn/shared_examples/cdn_server'


describe "Main tests: #{CdnServer::CDN_SERVER} --> #{CdnServer::CDN_SERVER_TYPE}" do
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
    include_examples  'power_operations'
  end

  describe 'Perform disk action' do
    before :all do
      @disks_count_before_test = @vm.disks.count
    end

    include_examples 'disk_actions'
  end

  describe 'Network' do
    include_examples 'network'
  end

  describe 'Rerun edge srcipts' do
    include_examples 'rerun_edge_srcipt'
  end

  describe 'Notes' do
    include_examples 'notes'
  end

  describe 'Edit' do
    include_examples 'edit'

    it 'market place' do
      status = vm.add_to_marketplace
      vm.edit_market_place_status
      if status == false
        expect(vm.add_to_marketplace).to eq true
      else
        expect(vm.add_to_marketplace).to eq false
      end
    end
  end
end
