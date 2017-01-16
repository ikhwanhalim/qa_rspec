require 'spec_helper'
require './groups/instance_package_actions'

describe 'Instance Package functionality tests' do
  before(:all) do
    @ipa = InstancePackageActions.new.precondition
    @instance_package = @ipa.instance_package
  end

  after(:all) do
    @instance_package.remove
  end

  let(:instance_package) { @ipa.instance_package }

  describe 'Create Instance Package negative tests' do
    after { expect(@instance_package.api_response_code).to eq '422' }

    it 'Create Instance Package with empty label' do
      instance_package.create(label: '')
      expect(instance_package.errors['label']).to eq(["can't be blank"])
    end

    it 'Create Instance Package with cpus less than min' do
      instance_package.create(cpus: '0')
      expect(instance_package.errors['cpus']).to eq(["must be greater than or equal to 1"])
    end

    it 'Create Instance Package with cpus more than max' do
      instance_package.create(cpus: '9')
      expect(instance_package.errors['cpus']).to eq(["must be less than or equal to 8"])
    end

    it 'Create Instance Package with disk_size less than min' do
      instance_package.create(disk_size: '5')
      expect(instance_package.errors['disk_size']).to eq(["must be greater than or equal to 6"])
    end

    it 'Create Instance Package with disk_size more than max' do
      instance_package.create(disk_size: '101')
      expect(instance_package.errors['disk_size']).to eq(["must be less than or equal to 100"])
    end

    it 'Create Instance Package with memory less than min' do
      instance_package.create(memory: '127')
      expect(instance_package.errors['memory']).to eq(["must be greater than or equal to 128"])
    end

    it 'Create Instance Package with memory more than max' do
      instance_package.create(memory: '16385')
      expect(instance_package.errors['memory']).to eq(["must be less than or equal to 16384"])
    end

    it 'Create Instance Package with empty bandwidth' do
      instance_package.edit(bandwidth: ' ')
      expect(instance_package.errors['bandwidth']).to eq(["can't be blank", "is not a number"])
    end

    it 'Create Instance Package with bandwidth more than max' do
      instance_package.edit(bandwidth: '451')
      expect(instance_package.errors['bandwidth']).to eq(["must be less than or equal to 450"])
    end
  end

  describe 'Edit Instance Package negative tests' do
    after { expect(@instance_package.api_response_code).to eq '422' }

    it 'Edit Instance Package with empty label' do
      instance_package.edit(label: '')
      expect(instance_package.errors['label']).to eq(["can't be blank"])
    end

    it 'Edit Instance Package with cpus less than min' do
      instance_package.edit(cpus: '0')
      expect(instance_package.errors['cpus']).to eq(["must be greater than or equal to 1"])
    end

    it 'Edit Instance Package with cpus more than max' do
      instance_package.edit(cpus: '9')
      expect(instance_package.errors['cpus']).to eq(["must be less than or equal to 8"])
    end

    it 'Edit Instance Package with disk_size less than min' do
      instance_package.edit(disk_size: '5')
      expect(instance_package.errors['disk_size']).to eq(["must be greater than or equal to 6"])
    end

    it 'Edit Instance Package with disk_size more than max' do
      instance_package.edit(disk_size: '101')
      expect(instance_package.errors['disk_size']).to eq(["must be less than or equal to 100"])
    end

    it 'Edit Instance Package with memory less than min' do
      instance_package.edit(memory: '100')
      expect(instance_package.errors['memory']).to eq(["must be greater than or equal to 128"])
    end

    it 'Edit Instance Package with memory more than max' do
      instance_package.edit(memory: '16385')
      expect(instance_package.errors['memory']).to eq(["must be less than or equal to 16384"])
    end

    it 'Edit Instance Package with empty bandwidth' do
      instance_package.edit(bandwidth: ' ')
      expect(instance_package.errors['bandwidth']).to eq(["can't be blank", "is not a number"])
    end

    it 'Edit Instance Package with bandwidth more than max' do
      instance_package.edit(bandwidth: '451')
      expect(instance_package.errors['bandwidth']).to eq(["must be less than or equal to 450"])
    end
  end

  describe 'Edit Instance Package positive tests' do
    before (:all) do
      @data = {
          label: @label || "InstancePackage-#{SecureRandom.hex(1)}",
          cpus: '2',
          disk_size: '10',
          memory: '256',
          bandwidth: '0'
      }
      @instance_package.edit(@data)
    end

    after { expect(@instance_package.api_response_code).to eq '200' }

    it 'Edit Instance Package label' do
      expect(instance_package.label).to eq @data[:label]
    end

    it 'Edit Instance Package cpus' do
      expect(instance_package.cpus.to_s).to eq @data[:cpus]
    end

    it 'Edit Instance Package disk_size' do
     expect(instance_package.disk_size.to_s).to eq @data[:disk_size]
    end

    it 'Edit Instance Package memory' do
      expect(instance_package.memory.to_s).to eq @data[:memory]
    end

    it 'Edit Instance Package bandwidth' do
      expect(instance_package.bandwidth.to_s).to eq @data[:bandwidth]
    end
  end
end