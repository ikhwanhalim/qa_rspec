require './groups/virtual_server_on_vcenter'

class VCenterVsTestCases

  attr_reader :env

  def initialize(env)
    @env = env
  end

  def executable?
    Log.info('============================== Precondition check and recovery ==============================')
    env.virtual_machine.info_update
    if env.virtual_machine.suspended
      env.virtual_machine.unsuspend
      env.virtual_machine.info_update
    end
    if env.virtual_machine.locked
      env.virtual_machine.unlock
      env.virtual_machine.info_update
    end
    if !env.virtual_machine.up?
      env.virtual_machine.info_update
      env.virtual_machine.start_up if !env.virtual_machine.booted
    end
    env.virtual_machine.up?
  end
end

class VCenterVsPowerOptions < VCenterVsTestCases

  def execute
    env.virtual_machine.stop
    Log.error('Virtual server not stopped after power off') if !env.virtual_machine.down?
    env.virtual_machine.start_up
    Log.error('Virtual server not running after startup') if !env.virtual_machine.up?
    env.virtual_machine.shut_down
    Log.error('Virtual server not stopped after shut down') if !env.virtual_machine.down?
    env.virtual_machine.start_up
    Log.error('Virtual server not running after startup') if !env.virtual_machine.up?
    env.virtual_machine.reboot
    Log.error('Virtual server not running after reboot') if !env.virtual_machine.up?
  end
end

class VCenterVsSuspendOptions < VCenterVsTestCases

  def execute
    env.virtual_machine.suspend
    env.virtual_machine.info_update
    Log.error('Virtual machine expect to be suspended') if !env.virtual_machine.suspended
    Log.error('Virtual server not stopped after suspend') if !env.virtual_machine.down?
    env.virtual_machine.unsuspend
    env.virtual_machine.info_update
    Log.error('Virtual machine expect to be not suspended') if env.virtual_machine.suspended
    Log.error('Virtual server still should be stopped after unsuspend') if !env.virtual_machine.down?
    env.virtual_machine.start_up
    Log.error('Virtual server not running after startup') if !env.virtual_machine.up?
  end
end

class VCenterVsRebuildOperation < VCenterVsTestCases

  def executable?
    env.template.type == 'ImageTemplate' && super
  end

  def execute
    env.virtual_machine.rebuild
    Log.error('Virtual server not running after rebuild') if !env.virtual_machine.up?
  end
end

class VCenterVSPrimaryDiskOperations < VCenterVsTestCases

  def execute
    disk_size_on_interface = env.virtual_machine.disk.disk_size
    disk_size_on_vm = env.virtual_machine.ssh_execute("fdisk -l | grep 'Disk' | grep 'dev' | grep -v 'mapper' | awk '{print \\$5}'").last.to_f/1024/1024/1024
    Log.error("Disk size on VM is not correct initially, expected #{disk_size_on_interface} but got #{disk_size_on_vm}") if disk_size_on_interface != disk_size_on_vm
    # new_size = env.virtual_machine.disk.disk_size + 5
    # env.virtual_machine.disk.edit(disk_size: new_size)
    # Log.error('Virtual server not running after increase primary disk size') if !env.virtual_machine.up?
    # disk_size_on_interface = env.virtual_machine.disk.disk_size
    # disk_size_on_vm = env.virtual_machine.ssh_execute("fdisk -l | grep 'Disk' | grep 'dev' | grep -v 'mapper' | awk '{print \\$5}'").last.to_f/1024/1024/1024
    # Log.error("Disk size on VM is not correct after increase primary disk size, expected #{disk_size_on_interface} but got #{disk_size_on_vm}") if disk_size_on_interface != disk_size_on_vm
    # VMWare do not support decrease disk size
  end
end

class VCenterVSAdditionalDiskOperations < VCenterVsTestCases

  def execute
     env.virtual_machine.add_disk
     env.virtual_machine.disk('additional').wait_for_build
     Log.error('Virtual server not running after adding') if !env.virtual_machine.up?
     disk_size_on_interface = env.virtual_machine.disk('additional').disk_size
     disk_size_on_vm = env.virtual_machine.ssh_execute("fdisk -l | grep 'Disk' | grep 'dev' | grep -v 'mapper' | awk '{print \\$5}'").last.to_f/1024/1024/1024
     Log.error("Additional disk size on VM is not correct initially, expected #{disk_size_on_interface} but got #{disk_size_on_vm}") if disk_size_on_interface != disk_size_on_vm
     new_size = env.virtual_machine.disk('additional').disk_size + 5
     env.virtual_machine.disk('additional').edit(disk_size: new_size)
     env.virtual_machine.disk('additional').wait_for_resize
     env.virtual_machine.disk('additional').wait_for_update_fstab
     Log.error('Virtual server not running after increase additional disk size') if !env.virtual_machine.up?
     disk_size_on_interface = env.virtual_machine.disk('additional').disk_size
     disk_size_on_vm = env.virtual_machine.ssh_execute("fdisk -l | grep 'Disk' | grep 'dev' | grep -v 'mapper' | awk '{print \\$5}'").last.to_f/1024/1024/1024
     Log.error("Additional disk size on VM is not correct after increase, expected #{disk_size_on_interface} but got #{disk_size_on_vm}") if disk_size_on_interface != disk_size_on_vm
  end
end