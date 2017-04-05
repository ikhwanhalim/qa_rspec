require 'spec_helper'
require './groups/group_actions'

describe 'Network Groups functionality tests' do
  before(:all) do
    @ga = GroupActions.new.precondition
    @network_group = @ga.network_group
  end

  let(:network_group) { @ga.network_group }

  describe 'Network Zones tests' do

    describe 'Adding a NZ with enabled preconfigured_only option' do
      after(:all) do
        @network_group.remove
      end

      it "NZ with 'virtual' server type should be created" do
        network_group.create(preconfigured_only: true)
        expect(network_group.api_response_code).to eq '201'
        expect(network_group.server_type).to eq 'virtual'
        expect(network_group.preconfigured_only).to be true
      end

      it "NZ with 'vpc' server type should not be created" do
        network_group.create(server_type: 'vpc', preconfigured_only: true)
        expect(network_group.errors['preconfigured_only']).to eq(["Preconfigured only option is not allowed for vpc"])
        expect(network_group.api_response_code).to eq '422'
      end

      #TODO
      it "NZ with 'smart' server type should not be created" do
        skip('Not implemented yet')
      end

      #TODO
      it "NZ with 'baremetal' server type should not be created" do
        skip('Not implemented yet')
      end
    end

    describe 'Edit preconfigured_only option for NZ' do
      after do
        @network_group.remove
      end

      it "Enable preconfigured_only option for NZ with 'virtual' server type" do
        network_group.create
        network_group.edit(preconfigured_only: true)
        expect(network_group.api_response_code).to eq '200'
        expect(network_group.server_type).to eq 'virtual'
        expect(network_group.preconfigured_only).to be true
      end

      it "Enable preconfigured_only option for NZ with 'vpc' server type" do
        network_group.create(server_type: 'vpc')
        network_group.edit(preconfigured_only: true)
        expect(network_group.api_response_code).to eq '422'
        expect(network_group.server_type).to eq 'vpc'
        expect(network_group.preconfigured_only).to be false
      end
    end
  end
end


