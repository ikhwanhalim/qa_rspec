require './groups/release_template'

describe 'Templates Tests' do
  before :all do
    @rt = ReleaseTemplate.new.precondition
  end

  let(:vm) { @rt.vm }
  let(:bs) { @rt.bs }

  after :all do
    @rt.cleanup_vm
  end

  it 'Scan built VM for viruses' do
    vm.stop
    bs.mount_vm_primary_disk
    bs.scan_disk
    bs.umount_vm_primary_disk
  end

  it 'Check basic power cycle actions' do
  end

  it 'Should be possible to update OS (yum/apt-get) and check boot availability' do
  end

  it 'Make backup, convert it to template and build new VS based on new Template' do
  end
end