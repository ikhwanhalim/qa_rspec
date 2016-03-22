require 'spec_helper'
require './groups/rake_tests'

describe 'Performing configuration test' do
  before :all do
    @interface = RakeTests.new
  end

  let(:enable_incremental) { SshCommands::OnControlPanel.enable_incremantal_backups }
  let(:enable_normal)      { SshCommands::OnControlPanel.enable_normal_backups }
  let(:backup_status)      { @interface.get('/settings/edit').settings.allow_incremental_backups }

  it 'should be able set incremental backuops via rake task' do
    expect(@interface.run_on_cp enable_incremental).to be true
    expect(backup_status).to be true
  end

  it 'should be able set normal backups via rake task' do
    expect(@interface.run_on_cp enable_normal).to be true
    expect(backup_status).to be false
  end
end