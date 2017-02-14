require 'spec_helper'
require './groups/group_actions'

describe 'Hypervizor Groups functionality tests' do
  before(:all) do
    @ga = GroupActions.new.precondition
    @hypervisor_group = @ga.hypervisor_group
  end

  let(:hypervizor_group) { @ga.hypervisor_group }

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
end

