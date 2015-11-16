require './groups/virtual_server_actions'

describe 'VIRTUAL MACHINE REGRESSION AUTOTEST' do
  before :all do
    @vsa = VirtualServerActions.new.precondition
    @vm = @vsa.virtual_machine
    @iso = @vsa.iso
    (@vm.up?).should be true
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

    it 'Suspend/Unsuspend Virtual Machine' do
      @vm.suspend.should be_truthy
      @vm.wait_for_stop.should be_truthy
      @vm.exist_on_hv?.should be_falsey
      @vm.suspend.should be_truthy    #unsuspend VM before deleting
      @vm.exist_on_hv?.should be_falsey
    end
  end

  describe 'Migrate Virtual Machine operations' do
    it 'Hot Migrate VM' do
      skip ('VM Template do not support Hot migration') unless @vm.template['allowed_hot_migrate']
      skip ('There is no available HV to migrate to') unless @vm.hv_to_migrate_exist?
      @vm.hot_migrate
      @vm.exist_on_hv?.should be_truthy
      @vm.ssh_port_opened.should be_truthy
    end

    it 'Cold migration' do
      skip ('There is no available HV to migrate to') unless @vm.hv_to_migrate_exist?
      @vm.cold_migrate
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

  describe 'Reboot in recovery operation' do
    it 'Reboot in recovery Operations' do
      @vm.recovery_reboot
      @vm.wait_for_reboot
      @vm.exist_on_hv?.should be_truthy
      @vm.ssh_port_opened.should be_truthy
      @vm.recovery?.should be_truthy
      # return to normal stance
      @vm.reboot
      @vm.wait_for_reboot
      @vm.exist_on_hv?.should be_truthy
      @vm.ssh_port_opened.should be_truthy
      @vm.recovery?.should be_falsey
    end
  end

  #Reboot VS from ISO
  describe "Reboot VS from ISO" do
    after :all do
      @iso.remove
    end

    it 'Reboot VS from ISO if not enough memory' do
      @vm.reboot_from_iso(@iso.iso_id)
      expect(@vm.api_response_code).to eq '422'
    end

    it 'ISO id should be nil' do
      expect(@vm.iso_id).to eq nil
    end

    it 'Reboot VS from ISO' do
      skip
    end
  end
end