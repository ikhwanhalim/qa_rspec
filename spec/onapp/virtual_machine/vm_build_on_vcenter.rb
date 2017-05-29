require 'spec_helper'
require 'rspec'
describe 'VIRTUAL MACHINE ON VMWARE (VCENTER) REGRESSION AUTOTEST' do

  before :all do
    @env=VirtualServerOnVCenter.new.precondition('image')
  end

  after :all do
    @env.aftercondition
  end

  after :each do
    @env=@test.env
  end

  it 'Power Options' do
    @test = VCenterVsPowerOptions.new(@env)
    skip('')
    skip('Test case could not be executed. Some configuration do not satisfy requirements') if !@test.executable?
    @test.execute
  end

  it 'Suspend Options' do
    @test = VCenterVsSuspendOptions.new(@env)
    skip('Test case could not be executed. Some configuration do not satisfy requirements') if !@test.executable?
    @test.execute
  end

  it 'Rebuild Option' do
    skip('')
    @test = VCenterVsRebuildOperation.new(@env)
    skip('Test case could not be executed. Some configuration do not satisfy requirements') if !@test.executable?
    @test.execute
  end

  it 'Primary disk operations' do
    skip('')
    @test = VCenterVSPrimaryDiskOperations.new(@env)
    skip('Test case could not be executed. Some configuration do not satisfy requirements') if !@test.executable?
    @test.execute
  end

  it 'Additional disk operations' do
    @test = VCenterVSAdditionalDiskOperations.new(@env)
    skip('Test case could not be executed. Some configuration do not satisfy requirements') if !@test.executable?
    @test.execute
  end

end