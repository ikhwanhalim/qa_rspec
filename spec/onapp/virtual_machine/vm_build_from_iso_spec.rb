require 'spec_helper'
require './groups/virtual_server_build_from_iso'

describe 'Virtual Server build from ISO actions tests' do
  before :all do
    @ivsa = IsoVirtualServerActions.new.precondition
    if @ivsa
      @iso = @ivsa.iso
      @vm = @ivsa.virtual_machine
    else
      fail('/data not mounted')
    end
  end

  after :all do
    @vm.destroy if @ivsa
    @iso.remove
  end

  let(:vm) { @ivsa.virtual_machine }

  describe 'VM power operations' do
    it { expect(vm.exist_on_hv?).to be true }

    it 'Stop/Start Virtual Machine' do
      vm.stop
      binding.pry
      expect(vm.exist_on_hv?).to be false
      vm.start_up
      expect(vm.exist_on_hv?).to be true
    end

    it 'ShutDown/Start Virtual Machine' do
      vm.shut_down
      expect(vm.exist_on_hv?).to be false
      vm.start_up
      expect(vm.exist_on_hv?).to be true
    end

    it 'Reboot Virtual Machine' do
      vm.reboot
      expect(vm.exist_on_hv?).to be true
    end

    it 'Suspend/Unsuspend Virtual Machine' do
      vm.suspend
      expect(vm.exist_on_hv?).to be false
      vm.start_up
      expect(vm.api_response_code).to eq '422'
      vm.unsuspend
      vm.start_up
      expect(vm.exist_on_hv?).to be true
    end
  end
end

