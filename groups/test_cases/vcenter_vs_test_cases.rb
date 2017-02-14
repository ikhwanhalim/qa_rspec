require './groups/virtual_serverr_on_vcenter'

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
    Log.error('Virtual serverr still should be stopped after unsuspend') if !env.virtual_machine.down?
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