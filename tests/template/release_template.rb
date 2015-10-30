require './groups/release_template'

describe 'Templates Tests' do
  before :all do
    @rt = ReleaseTemplate.new.precondition
  end

  let(:virtual_machine) { @rt.virtual_machine }
  let(:backup_server) { @rt.backup_server }

  after :all do
    @rt.virtual_machine.destroy
  end

  it 'Virtual server should be started' do
    (virtual_machine.up?).should be true
  end

  it 'Virtual server should be stopped' do
    virtual_machine.stop
    (virtual_machine.down?).should be true
  end

  it 'Scan built VM for viruses' do
    if virtual_machine.up?
      virtual_machine.stop
      (virtual_machine.down?).should be true
    end
    backup_server.mount_vm_primary_disk
    backup_server.scan_disk
    backup_server.umount_vm_primary_disk
    virtual_machine.start_up
    (virtual_machine.up?).should be true
  end

  it 'Should be possible to update OS (yum/apt-get) and check boot availability' do
    virtual_machine.update_os
    virtual_machine.reboot
    (virtual_machine.up?).should be true
  end

  it 'Make backup, convert it to template and build new VS based on new Template' do
  end
end