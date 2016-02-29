require 'spec_helper'
require './groups/virtual_server_actions'

describe 'Windows Virtual Server actions tests' do
  before :all do
    @vsa = VirtualServerActions.new.precondition
    @vm = @vsa.virtual_machine
  end

  after :all do
    @vm.destroy
  end

  let(:vm) { @vsa.virtual_machine }

  let(:version) { @vsa.version }

  it 'VM should be created' do
    true
  end
end