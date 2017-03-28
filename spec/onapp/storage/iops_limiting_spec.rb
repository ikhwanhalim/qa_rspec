require 'spec_helper'
require './groups/iops_limiting_actions'

# IOPS Limiting Feature should be working for static HVs and cloudboots with IS and without.
# 2 HVs in a zone are minimum requirements as migration should be checked.
# Important! the limiting should be measured only inside of a Virtual Machine

describe  'IOPS Limiting' do
  before :all do
    @io = IopsLimiting.new.precondition
    @io_new = { create: -> { IopsLimiting.new.precondition } }
    @vm = @io.virtual_machine
    @primary_disk = @vm.disks.first
    @swap_disk = @vm.disks.last
    @vm.pinged?
    sleep(30)
    @io.install_io_ping(@vm)
    @data_store_limits    =  { create: -> { @io.set_ds_io_limits(@io.data_store_route,
                                                                 200, 200, 4, 4) } }
    @primary_disk_limits  =  { create: -> { @io.set_disk_io_limits(@primary_disk.id,
                                                                   true, 300, 400, 6, 6) } }
    @swap_disk_limits     =  { create: -> { @io.set_disk_io_limits(@swap_disk.id,
                                                                   true, 300, 400, 6, 6) } }
  end

  after :all do
    @vm.destroy
  end

  let (:io)             { @io }
  let (:ds_limit)       { @data_store_limits }
  let (:p_disk_limit)   { @primary_disk_limits }
  let (:s_disk_limit)   { @swap_disk_limits }
  let (:vm)             { @vm }
  let (:p_disk)         { @primary_disk }
  let (:s_disk)         { @swap_disk }

  context "iops limiting permissions disabled" do
    before :all do
      @io.run_on_cp(SshCommands::OnControlPanel.disable_io_limiting)
      @io.run_on_cp(SshCommands::OnControlPanel.restart_httpd)
      @io.check_services
    end

    after :all do
      @io.run_on_cp(SshCommands::OnControlPanel.enable_io_limiting)
      @io.run_on_cp(SshCommands::OnControlPanel.restart_httpd)
      @io.check_services
    end

    it 'should not be possible to set data_store iops limits' do
      response = ds_limit[:create].call()
      expect(response).to eq({"errors"=>["IO limits are not available"]})
    end

    it 'should not be possible to set disk iops limits' do
      response = s_disk_limit[:create].call()
      expect(response).to eq({"errors"=>["IO limits are not available"]})
    end
  end

  context "iops limiting permissions enabled" do
    it 'should be possible to set iops limits for data_store' do
      response = ds_limit[:create].call()
      code = response.code
      expect(code).to eq '204'
    end

    it 'should be possible to set iops limits for disk' do
      response = s_disk_limit[:create].call()
      code = response.code
      expect(code).to eq '204'
    end
  end

  context "iops limiting for virtual vachine" do
    before :all do
      @precondition = @io_new[:create].call()
      @new_vm = @precondition.virtual_machine
      @new_vm.pinged?
      sleep(30)
      @io.install_io_ping(@new_vm)
    end

    after :all do
      @new_vm.destroy
    end

    let (:new_vm) { @new_vm }

    it 'should set iops limits for VirtualMachine through data_store and have it working' do
      expect(io.disk_vs_limits(vm)).to be true
    end

    it 'should work after migration' do
      vm.migrate(io.find_hv_for_migration)
      vm.pinged?
      sleep(30)
      expect(io.disk_vs_limits(vm)).to be true
    end

    it 'should work after reboot' do
      vm.reboot
      vm.pinged?
      sleep(30)
      expect(io.disk_vs_limits(vm)).to be true
    end

    it 'should work for newly created VirtualMachine' do
      expect(io.disk_vs_limits(new_vm)).to be true
    end
  end

  context "iops limiting for disk" do
    before :all do
      @cold_disk = @vm.add_disk({
                                    label:"cold_attached",
                                    disk_size:"1",
                                    hot_attach:"0",
                                    is_swap:"0",
                                    require_format_disk:"1",
                                    mounted:"1",
                                    mount_point:"/mnt/onapp-disk-cold_attached",
                                    file_system:"ext3",

                                })
      @cold_disk.wait_for_build
      @vm.pinged?
      sleep(60)
      @hot_disk  = @vm.add_disk({
                                    label: "hot_attached",
                                    disk_size:"1",
                                    hot_attach:"1",
                                    is_swap:"0",
                                    require_format_disk:"1",
                                    mounted:"1",
                                    mount_point:"/mnt/onapp-disk-hot_attached",
                                    file_system:"ext3"
                                })
      @hot_disk.wait_for_attach
      @vm.pinged?
      sleep(60)
    end

    let (:c_disk)   { @cold_disk }
    let (:h_disk)   { @hot_disk }
    let (:c_limits) { @c_limits }
    let (:h_limits) { @h_limits }

    it 'should set iops limits for disk and have it working' do
      p_disk_limit[:create].call()
      expect(io.disk_vs_limits(vm, p_disk)).to be true
    end

    it 'should not overwrite datastore limits over disk limits' do
      ds_limit[:create].call()
      expect(io.disk_vs_limits(vm, p_disk)).to be true
    end

    it 'should work for cold attached disk' do
      expect(io.attached_vs_limits(vm, c_disk)).to be true
    end

    it 'should work for hot attached disk' do
      expect(io.attached_vs_limits(vm, h_disk)).to be true
    end
  end
end


