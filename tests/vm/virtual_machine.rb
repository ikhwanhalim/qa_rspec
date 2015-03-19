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

  describe 'VM power operations' do
    it 'Stop/Start Virtual Machine' do
      @vm.ssh_port_opened.should be_truthy
      @vm.exist_on_hv?.should be_truthy

      @vm.stop.should be_truthy      
      @vm.wait_for_stop.should be_truthy
      @vm.exist_on_hv?.should be_falsey

      @vm.start_up.should be_truthy      
      @vm.wait_for_start.should be_truthy
      @vm.exist_on_hv?.should be_truthy
      @vm.ssh_port_opened.should be_truthy            
    end
    it 'ShutDown/Start Virtual Machine' do
      @vm.ssh_port_opened.should be_truthy
      @vm.exist_on_hv?.should be_truthy

      @vm.shut_down.should be_truthy      
      @vm.wait_for_stop.should be_truthy
      @vm.exist_on_hv?.should be_falsey


      @vm.start_up.should be_truthy      
      @vm.wait_for_start.should be_truthy
      @vm.exist_on_hv?.should be_truthy
      @vm.ssh_port_opened.should be_truthy
    end    
    it 'Reboot Virtual Machine' do
      @vm.reboot.should be_truthy
      @vm.wait_for_reboot
      @vm.exist_on_hv?.should be_truthy
      @vm.ssh_port_opened.should be_truthy
    end
  end
  describe 'Resize Virtual Server Operations' do
    it 'Resize RAM memory (Increase/Decrease)' do
      skip 'Unable to perform test without Template resize_without_reboot_policy policy' if @vm.resize_support?
      @vm.reboot.should be_truthy # To reset max_mem
      @vm.wait_for_reboot

      @vm.edit('memory', 'incr', 256)
      @vm.exist_on_hv?.should be_truthy
      @vm.ssh_port_opened.should be_truthy
      @vm.memory_correct?.should be_truthy

      @vm.edit('memory', 'decr', 128)
      @vm.exist_on_hv?.should be_truthy
      @vm.ssh_port_opened.should be_truthy
      @vm.memory_correct?.should be_truthy

      @vm.edit('memory', 'set', 512)
      @vm.exist_on_hv?.should be_truthy
      @vm.ssh_port_opened.should be_truthy
      @vm.memory_correct?.should be_truthy
    end
    it 'Resize CPU cores (Increase/Decrease)' do
      skip 'Unable to perform test without Template resize_without_reboot_policy policy' if @vm.resize_support?
      @vm.edit('cpus', 'incr', 2)
      @vm.exist_on_hv?.should be_truthy
      @vm.ssh_port_opened.should be_truthy
      @vm.cpus_correct?.should be_truthy

      @vm.edit('cpus', 'decr', 1)
      @vm.exist_on_hv?.should be_truthy
      @vm.ssh_port_opened.should be_truthy
      @vm.cpus_correct?.should be_truthy

      @vm.edit('cpus', 'set', 1)
      @vm.exist_on_hv?.should be_truthy
      @vm.ssh_port_opened.should be_truthy
      @vm.cpus_correct?.should be_truthy
    end
    it 'Resize CPU share (Increase/Decrease)' do
      skip 'Unable to perform test without Template resize_without_reboot_policy policy' if @vm.resize_support?
      skip 'CPU shares always 100% ' if @vm.hypervisor['distro'] == 'centos5' && @vm.hypervisor['hypervisor_type'] == 'kvm'
      @vm.edit('cpu_shares', 'incr', 50)
      @vm.exist_on_hv?.should be_truthy
      @vm.ssh_port_opened.should be_truthy
      @vm.cpu_shares_correct?.should be_truthy

      @vm.edit('cpu_shares', 'decr', 25)
      @vm.exist_on_hv?.should be_truthy
      @vm.ssh_port_opened.should be_truthy
      @vm.cpu_shares_correct?.should be_truthy

      @vm.edit('cpu_shares', 'set', 1)
      @vm.exist_on_hv?.should be_truthy
      @vm.ssh_port_opened.should be_truthy
      @vm.cpu_shares_correct?.should be_truthy

    end
  end

  describe 'VM disks operations' do
    it 'Should be possible edit primary disk' do
      @vm.edit_disk
    end
  end

  describe 'Network operations' do
    it 'Should be possible to do something' do
      true
    end
  end    
end