require './groups/virtual_server_actions'

describe 'VIRTUAL MACHINE REGRESSION AUTOTEST' do
  before :all do
    @vsa = VirtualServerActions.new.precondition
    @vm = @vsa.virtual_machine
  end

  after :all do
    @vm.destroy
    @vm.wait_for_destroy
  end

  let(:vm)  { @vsa.virtual_machine }
  let(:iso) { @vsa.iso }

  describe 'VM power operations' do
    describe 'After build' do
      it { expect(vm.up?).to be true }

      it { expect(vm.exist_on_hv?).to be true }
    end

    it 'Stop/Start Virtual Machine' do
      vm.stop
      expect(vm.down?).to be false
      vm.start_up
      expect(vm.up? && vm.exist_on_hv?).to be true
    end

    it 'ShutDown/Start Virtual Machine' do
      vm.shut_down
      expect(vm.down?).to be true
      vm.start_up
      expect(vm.up? && vm.exist_on_hv?).to be true
    end

    it 'Reboot Virtual Machine' do
      vm.reboot
      expect(vm.up? && vm.exist_on_hv?).to be true
    end

    it 'Suspend/Unsuspend Virtual Machine' do
      vm.suspend
      expect(vm.down?).to be true
      expect(vm.exist_on_hv?).to be false
      vm.start_up
      expect(vm.api_response_code).to eq '422'
      vm.unsuspend
      vm.start_up
      expect(vm.up? && vm.exist_on_hv?).to be true
    end
  end

  # describe 'Migrate Virtual Machine operations' do
  #   it 'Hot Migrate VM' do
  #     skip ('VM Template do not support Hot migration') unless @vm.template['allowed_hot_migrate']
  #     skip ('There is no available HV to migrate to') unless @vm.hv_to_migrate_exist?
  #     @vm.hot_migrate
  #     @vm.exist_on_hv?.should be_truthy
  #     @vm.ssh_port_opened.should be_truthy
  #   end
  #
  #   it 'Cold migration' do
  #     skip ('There is no available HV to migrate to') unless @vm.hv_to_migrate_exist?
  #     @vm.cold_migrate
  #     @vm.exist_on_hv?.should be_truthy
  #     @vm.ssh_port_opened.should be_truthy
  #   end
  # end

  describe 'Resize Virtual Server Operations' do
    before :all do
      @default = {
        label: @vm.label,
        cpus: @vm.cpus,
        cpu_shares: @vm.cpu_shares,
        memory: @vm.memory
      }
    end

    describe 'Increase' do
      before :all do
        @increased_params = {
          label: 'AutoTestChanged',
          cpus: @vm.cpus + 1,
          cpu_shares: @vm.cpu_shares + 10,
          memory: @vm.memory + 256
        }
        @vm.edit(@increased_params)
      end

      it 'Lable has been changed' do
        expect(vm.label).to eq @increased_params[:label]
      end

      it 'RAM' do

      end

      it 'CPUs' do

      end

      it 'CPU shares' do

      end
    end

    describe 'Decrease' do
      before :all do
        @decreased_params = {
            cpus: @vm.cpus - 1,
            cpu_shares: @vm.cpu_shares - 10,
            memory: @vm.memory - 256
        }
        @vm.edit(@decreased_params)
      end

      it 'RAM' do

      end

      it 'CPUs' do

      end

      it 'CPU shares' do

      end
    end

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
      skip
    end
  end

  describe 'Network operations' do
    it 'Should be possible to do something' do
      skip
    end
  end

  describe 'Reboot in recovery operation' do
    it 'Reboot in recovery Operations' do
      vm.reboot(recovery: true)
      expect(vm.ssh_execute('hostname')).to include 'recovery'
      vm.reboot
      expect(vm.ssh_execute('hostname')).to include vm.hostname
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