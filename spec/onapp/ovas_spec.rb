require 'spec_helper'
require './groups/ova_actions'

describe 'OVA functionality tests' do
  before(:all) do
    @oa = OvaActions.new.precondition
    @ova = @oa.ova
  end

  after(:all) do
    @ova.remove if @oa
  end

  let(:ova) { @oa.ova }

  it 'OVA template should exist in templates' do
    expect(ova.exists_in?(folder: 'templates')). to be true
  end

  it 'Downloaded OVA iso should not exist in data' do
    expect(ova.exists_in?(folder: 'data')). not_to be true
  end

  describe 'Create OVA negative tests' do

    let(:label_edited) {ova.label + 'edited' }

    after { expect(@ova.api_response_code).to eq '422' }

    it 'Create OVA with empty label' do
      ova.create(label: '')
      expect(ova.errors['label']).to eq(["can't be blank"])
    end

    it 'Create OVA with already taken label' do
      ova.create(label: ova.label)
      expect(ova.errors['label']).to eq(["has already been taken"])
    end

    it 'Create OVA with min_memory_size less than 128' do
      ova.create(min_memory_size: 127, label: label_edited)
      expect(ova.errors['min_memory_size']).to eq(["must be greater than or equal to 128"])
    end

    it 'Create OVA with min_disk_size less than 1' do
      ova.create(min_disk_size: 0, label: label_edited)
      expect(ova.errors['min_disk_size']).to eq(["must be greater than or equal to 1"])
    end

    it 'Create OVA with empty version' do
      ova.create(version: '', label: label_edited)
      expect(ova.errors['version']).to eq(["can't be blank"])
    end

    it 'Create OVA with empty backup_server_id' do
      ova.create(backup_server_id: '', label: label_edited)
      expect(ova.errors['backup_server_id']).to eq(["can't be blank"])
    end

    it 'Create OVA with xen virtualization' do
      ova.create(virtualization: ['xen'], label: label_edited)
      expect(ova.errors['virtualization']).to eq(["type 'xen' is incompatible"])
    end

    it 'Create OVA with empty file_url' do
      ova.create(file_url: '', label: label_edited)
      expect(ova.errors['file_url']).to eq(["can't be blank"])
    end

    it 'Create OVA with empty operating_system' do
      skip('Bug')
      ova.create(operating_system: '', label: label_edited)
      expect(ova.errors['operating_system']).to eq(["can't be blank"])
    end

  end

  describe 'Edit OVA negative tests' do
    after { expect(@ova.api_response_code).to eq '422' }

    it 'Edit OVA with the min_memory_size less than 128' do
      ova.edit(min_memory_size: 127)
      expect(ova.errors['min_memory_size']).to eq(["must be greater than or equal to 128"])
    end

    it 'Edit OVA with min_disk_size less than 1' do
      ova.edit(min_disk_size: 0)
      expect(ova.errors['min_disk_size']).to eq(["must be greater than or equal to 1"])
    end

    it 'Edit OVA with the empty version' do
      ova.edit(version: '')
      expect(ova.errors['version']).to eq(["can't be blank"])
    end

    it 'Edit OVA with kvm_virtio virtualization type' do
      ova.edit(virtualization: ["kvm_virtio"])
      expect(ova.errors['virtualization']).to eq(["type 'kvm_virtio' is incompatible"])
    end

    it 'Edit OVA with incorrect operating_system' do
      skip('Bug')
      ova.edit(operating_system: 'freebsd')
      expect(ova.errors['operating_system']).to eq(["can't be blank"])
    end
  end

  describe 'Edit OVA positive tests' do
    before (:all) do
      @data = {
          label: "ISO-#{SecureRandom.hex(4)}",
          min_memory_size: 256,
          min_disk_size: 20,
          version: '2.0',
          operating_system: 'other',
          operating_system_distro: 'other',
      }
      @ova.edit(@data)
    end

    it 'Edit OVA label' do
      expect(ova.label).to eq @data[:label]
    end

    it 'Edit OVA min memory size' do
      expect(ova.min_memory_size.to_i).to eq @data[:min_memory_size]
    end

    it 'Edit OVA min disk size' do
      expect(ova.min_disk_size).to eq @data[:min_disk_size]
    end

    it 'Edit OVA version' do
      expect(ova.version).to eq @data[:version]
    end

    it 'Edit OVA operating system' do
      expect(ova.operating_system).to eq @data[:operating_system]
    end

    it 'Edit OVA operating system distro' do
      expect(ova.operating_system_distro).to eq @data[:operating_system_distro]
    end
  end

  it 'Make OVA public' do
    expect(ova.user_id).not_to be_nil
    ova.make_public
    expect(ova.api_response_code).to eq '201'
    expect(ova.user_id).to be_nil
  end
end


