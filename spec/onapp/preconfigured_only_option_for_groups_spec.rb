require 'spec_helper'
require './groups/group_actions'

describe 'Add/Edit Groups with preconfigured_only option tests' do
  before(:all) do
    @ga = GroupActions.new.precondition
    @hypervisor_group = @ga.hypervisor_group
    @network_group = @ga.network_group
    @data_store_group = @ga.data_store_group
  end

  let(:hypervizor_group) { @hypervisor_group }
  let(:network_group) { @network_group }
  let(:data_store_group) { @data_store_group }

  describe 'Hypervizor Zones tests' do

    describe 'Adding a HZ with enabled preconfigured_only option' do
      after(:all) do
        @hypervisor_group.remove
      end

      it "HZ with 'virtual' server type should be created" do
        hypervizor_group.create(preconfigured_only: true)
        expect(hypervizor_group.api_response_code).to eq '201'
        expect(hypervizor_group.server_type).to eq 'virtual'
        expect(hypervizor_group.preconfigured_only).to be true
      end

      it "HZ with 'smart' server type should not be created" do
        hypervizor_group.create(server_type: 'smart', preconfigured_only: true)
        expect(hypervizor_group.errors['preconfigured_only']).to eq(["Preconfigured only option is not allowed for smart, baremetal and vpc servers"])
        expect(hypervizor_group.api_response_code).to eq '422'
      end

      it "HZ with 'baremetal' server type should not be created" do
        hypervizor_group.create(server_type: 'baremetal', preconfigured_only: true)
        expect(hypervizor_group.errors['preconfigured_only']).to eq(["Preconfigured only option is not allowed for smart, baremetal and vpc servers"])
        expect(hypervizor_group.api_response_code).to eq '422'
      end

      it "HZ with 'vpc' server type should not be created" do
        hypervizor_group.create(server_type: 'vpc', preconfigured_only: true)
        expect(hypervizor_group.errors['preconfigured_only']).to eq(["Preconfigured only option is not allowed for smart, baremetal and vpc servers"])
        expect(hypervizor_group.api_response_code).to eq '422'
      end
    end

    describe 'Edit preconfigured_only option for HZ' do
      after do
        @hypervisor_group.remove
      end

      it "Enable preconfigured_only option for HZ with 'virtual' server type" do
        hypervizor_group.create
        hypervizor_group.edit(preconfigured_only: true)
        expect(hypervizor_group.api_response_code).to eq '200'
        expect(hypervizor_group.server_type).to eq 'virtual'
        expect(hypervizor_group.preconfigured_only).to be true
      end

      it "Enable preconfigured_only option for HZ with 'smart' server type" do
        hypervizor_group.create(server_type: 'smart')
        hypervizor_group.edit(preconfigured_only: true)
        expect(hypervizor_group.api_response_code).to eq '422'
        expect(hypervizor_group.server_type).to eq 'smart'
        expect(hypervizor_group.preconfigured_only).to be false
      end

      it "Enable preconfigured_only option for HZ with 'baremetal' server type" do
        hypervizor_group.create(server_type: 'baremetal')
        hypervizor_group.edit(preconfigured_only: true)
        expect(hypervizor_group.api_response_code).to eq '422'
        expect(hypervizor_group.server_type).to eq 'baremetal'
        expect(hypervizor_group.preconfigured_only).to be false
      end

      it "Enable preconfigured_only option for HZ with 'vpc' server type" do
        hypervizor_group.create(server_type: 'vpc')
        hypervizor_group.edit(preconfigured_only: true)
        expect(hypervizor_group.api_response_code).to eq '422'
        expect(hypervizor_group.server_type).to eq 'vpc'
        expect(hypervizor_group.preconfigured_only).to be false
      end
    end

    describe 'Enable preconfigured_only option for HZ' do
      before(:all) do
        @hypervisor = @ga.hypervisor
        @hypervisor1 = @hypervisor.create
        @hypervisor2 = @hypervisor.create(cpu_units: '990')
        @hypervisor_group = @ga.hypervisor_group
        @hypervisor_group.create(preconfigured_only: false)
        @hypervisor_group.attach_hypervisor(@hypervisor1.id)
        @hypervisor_group.attach_hypervisor(@hypervisor2.id)
      end

      after(:all) do
        @hypervisor.remove(@hypervisor1.id)
        @hypervisor.remove(@hypervisor2.id)
        @hypervisor_group.remove
      end

      let(:hypervizor_group) { @hypervisor_group}

      it 'Enable preconfigured_only option for HZ which contain different amount of cpu units' do
        hypervizor_group.edit(preconfigured_only: true)
        expect(hypervizor_group.errors['base']).to eq(["Compute resources in this zone have different amount of cpu units"])
        expect(hypervizor_group.api_response_code).to eq '422'
        expect(hypervizor_group.preconfigured_only).to be false
      end
    end
  end

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
        skip('Not implemented yet for smart & baremetal NZs')
      end

      #TODO
      it "NZ with 'baremetal' server type should not be created" do
        skip('Not implemented yet for smart & baremetal NZs')
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

  describe 'DataStore Zones tests' do

    describe 'Adding a DSZ with enabled preconfigured_only option' do
      after(:all) do
        @data_store_group.remove
      end

      it "DSZ with 'virtual' server type should be created" do
        data_store_group.create(preconfigured_only: true)
        expect(data_store_group.api_response_code).to eq '201'
        expect(data_store_group.server_type).to eq 'virtual'
        expect(data_store_group.preconfigured_only).to be true
      end

      it "DSZ with 'vpc' server type should not be created" do
        data_store_group.create(server_type: 'vpc', preconfigured_only: true)
        expect(data_store_group.errors['preconfigured_only']).to eq(["Preconfigured only option is not allowed for vpc"])
        expect(data_store_group.api_response_code).to eq '422'
      end

      #TODO
      it "DSZ with 'smart' server type should not be created" do
        skip('Not implemented yet for smart DSZ')
      end
    end

    describe 'Edit preconfigured_only option for DSZ' do
      after do
        @data_store_group.remove
      end

      it "Enable preconfigured_only option for DSZ with 'virtual' server type" do
        data_store_group.create
        data_store_group.edit(preconfigured_only: true)
        expect(data_store_group.api_response_code).to eq '200'
        expect(data_store_group.server_type).to eq 'virtual'
        expect(data_store_group.preconfigured_only).to be true
      end

      it "Enable preconfigured_only option for DSZ with 'vpc' server type" do
        data_store_group.create(server_type: 'vpc')
        data_store_group.edit(preconfigured_only: true)
        expect(data_store_group.api_response_code).to eq '422'
        expect(data_store_group.server_type).to eq 'vpc'
        expect(data_store_group.preconfigured_only).to be false
      end
    end
  end
end

