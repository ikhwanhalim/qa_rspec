require 'spec_helper'
require './groups/iso_actions'

describe 'ISO functionality tests' do
  before(:all) do
    @ia = IsoActions.new.precondition
    @iso = @ia.iso
  end

  after(:all) do
    @iso.remove
  end

  let(:iso) { @ia.iso }

  describe 'Create ISO negative tests' do
    after { expect(@iso.api_response_code).to eq '422' }

    it 'Create ISO with empty label' do
      iso.create(label: '')
      expect(iso.errors['label']).to eq(["can't be blank"])
    end

    it 'Create ISO with incorrect min_memory_size' do
      iso.create(min_memory_size: 0)
      expect(iso.errors['min_memory_size']).to eq(["must be greater than or equal to 128"])
    end

    it 'Create ISO with incorrect min_disk_size' do
      skip('Fixed 4.2')
      iso.create(min_disk_size: 0)
      expect(iso.errors['min_disk_size']).to eq(["must be greater than or equal to 1"])
    end

    it 'Create ISO with empty version' do
      iso.create(version: '')
      expect(iso.errors['version']).to eq(["can't be blank"])
    end

    it 'Create ISO with empty operating_system' do
      iso.create(operating_system: '')
      expect(iso.errors['operating_system']).to eq(["can't be blank"])
    end

    it 'Create ISO with empty virtualization' do
      iso.create(virtualization: [])
      expect(iso.errors['virtualization']).to eq(["can't be blank"])
    end

    it 'Create ISO with empty file_url' do
      iso.create(file_url: '')
      expect(iso.errors['file_url']).to eq(["can't be blank"])
    end
  end

  describe 'Edit ISO negative tests' do
    after { expect(@iso.api_response_code).to eq '422' }

    it 'Edit ISO with the min_memory_size less than 128' do
       iso.edit(min_memory_size: 100)
       expect(iso.errors['min_memory_size']).to eq(["must be greater than or equal to 128"])
    end

    it 'Edit ISO with incorrect min_disk_size' do
      skip('Fixed 4.2')
      iso.edit(min_disk_size: 0)
      expect(iso.errors['min_disk_size']).to eq(["must be greater than or equal to 1"])
    end

    it 'Edit ISO with the empty version' do
      iso.edit(version: '')
      expect(iso.errors['version']).to eq(["can't be blank"])
    end

    it 'Edit ISO with empty operating_system' do
      iso.edit(operating_system: '')
      expect(iso.errors['operating_system']).to eq(["can't be blank"])
    end

    it 'Edit ISO with incorrect virtualization type' do
      iso.edit(virtualization: ["xee"])
      expect(iso.errors['virtualization']).to eq(["type 'xee' is incompatible"])
    end
  end

  describe 'Edit ISO positive tests' do
    before (:all) do
      @data = {
        label: 'EditedISO',
        min_memory_size: 128,
        min_disk_size: 20,
        version: '2.0',
        operating_system: 'Freebsd',
        operating_system_distro: 'Debian',
        virtualization: ["kvm", "kvm_virtio"]
      }
      @iso.edit(@data)
    end

    it 'Edit ISO label' do
      expect(iso.label).to eq @data[:label]
    end

    it 'Edit ISO min memory size' do
      expect(iso.min_memory_size.to_i).to eq @data[:min_memory_size]
    end

    it 'Edit ISO min disk size' do
      expect(iso.min_disk_size).to eq @data[:min_disk_size]
    end

    it 'Edit ISO version' do
      expect(iso.version).to eq @data[:version]
    end

    it 'Edit ISO operating system' do
      expect(iso.operating_system).to eq @data[:operating_system]
    end

    it 'Edit ISO operating system distro' do
      expect(iso.operating_system_distro).to eq @data[:operating_system_distro]
    end

    it 'Edit ISO virtualization type' do
      expect(iso.virtualization).to eq @data[:virtualization]
    end
  end

  it 'Make ISO public' do
    iso.make_public
    expect(iso.api_response_code).to eq '201'
    expect(iso.user_id).to be_nil
  end
end
