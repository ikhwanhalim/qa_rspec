require 'virtual_machine/vm_base'

require 'pry'

describe 'VIRTUAL MACHINE REGRESSION AUTOTEST' do
  before :all do
    @vm = VirtualMachine.new
    @vm.create(ENV['TEMPLATE_MANAGER_ID'],ENV['VIRT_TYPE'])
    expect(@vm.is_created?).to be true
    expect(@vm.pinged?).to be true
  end
  after :all do
    @vm.destroy
    @vm.wait_for_destroy
  end

  describe 'Primary disk operations'  do
    it 'Edit Primary disk' do

      @vm.edit_disk(type:'primary', action:'incr', value:5)
      @vm.ssh_port_opened.should be_truthy
      @vm.check_primary_disk.should be_truthy

      @vm.edit_disk(type:'primary', action:'decr', value:3)
      @vm.ssh_port_opened.should be_truthy
      @vm.check_primary_disk.should be_truthy

      @vm.edit_disk(type:'primary', action:'set', value:@vm.template['min_disk_size'])
      @vm.ssh_port_opened.should be_truthy
      @vm.check_primary_disk.should be_truthy

    end
    it 'Migrate Primary disk' do
      @vm.migrate_disk(type:'primary')
      @vm.ssh_port_opened.should be_truthy
      @vm.check_primary_disk.should be_truthy
    end
  end

  describe 'SWAP Disk operations'  do
    it 'Edit SWAP Disk' do

      @vm.edit_disk(type:'swap', action:'incr', value:5)
      @vm.ssh_port_opened.should be_truthy
      @vm.check_swap_space.should be_truthy

      @vm.edit_disk(type:'swap', action:'decr', value:3)
      @vm.ssh_port_opened.should be_truthy
      @vm.check_swap_space.should be_truthy

      @vm.edit_disk(type:'swap', action:'set', value:1)
      @vm.ssh_port_opened.should be_truthy
      @vm.check_swap_space.should be_truthy

    end
    it 'Migrate SWAP disk' do
      @vm.migrate_disk(type:'swap')
      @vm.ssh_port_opened.should be_truthy
      @vm.check_swap_space.should be_truthy
    end
  end

  describe 'Additional Disk operations'  do
    it 'Add additional disk' do
      @@test_disk_id = @vm.add_disk(size:7)
      @vm.ssh_port_opened.should be_truthy
      @vm.check_additional_disk(@@test_disk_id).should be_truthy
    end
    it 'Edit additional Disk operations' do

      @vm.edit_disk(id:@@test_disk_id, action:'incr', value:5)
      @vm.ssh_port_opened.should be_truthy
      @vm.check_additional_disk(@@test_disk_id).should be_truthy

      @vm.edit_disk(id:@@test_disk_id, action:'decr', value:3)
      @vm.ssh_port_opened.should be_truthy
      @vm.check_additional_disk(@@test_disk_id).should be_truthy

      @vm.edit_disk(id:@@test_disk_id, action:'set', value:10)
      @vm.ssh_port_opened.should be_truthy
      @vm.check_additional_disk(@@test_disk_id).should be_truthy

    end
    it 'Migrate additional disk' do
      @vm.migrate_disk(id:@@test_disk_id)
      @vm.ssh_port_opened.should be_truthy
      @vm.check_additional_disk(@@test_disk_id).should be_truthy
    end
    it 'Destroy additional disk' do
      @vm.destroy_disk(@@test_disk_id)
      @vm.ssh_port_opened.should be_truthy
      @vm.check_additional_disk(@@test_disk_id).should be_falsey
    end

  end

  describe 'Additional SWAP disk operations'  do
    it 'Add additional SWAP disk' do
      @@test_swap_disk_id = @vm.add_disk(size:5, is_swap:true)
      @vm.ssh_port_opened.should be_truthy
      @vm.check_swap_space.should be_truthy
    end
    it 'Edit additional SWAP disk' do

      @vm.edit_disk(id:@@test_swap_disk_id, action:'incr', value:5)
      @vm.ssh_port_opened.should be_truthy
      @vm.check_swap_space.should be_truthy

      @vm.edit_disk(id:@@test_swap_disk_id, action:'decr', value:3)
      @vm.ssh_port_opened.should be_truthy
      @vm.check_swap_space.should be_truthy

      @vm.edit_disk(id:@@test_swap_disk_id, action:'set', value:1)
      @vm.ssh_port_opened.should be_truthy
      @vm.check_swap_space.should be_truthy

    end
    it 'Migrate additional SWAP disk' do
      @vm.migrate_disk(id:@@test_swap_disk_id)
      @vm.ssh_port_opened.should be_truthy
      @vm.check_swap_space.should be_truthy
    end
    it 'Destroy additional SWAP disk' do
      @vm.destroy_disk(@@test_swap_disk_id)
      @vm.ssh_port_opened.should be_truthy
      @vm.check_swap_space.should be_truthy
    end
  end

end