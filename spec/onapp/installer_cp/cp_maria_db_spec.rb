require 'spec_helper'
require './groups/installer_cp_actions'
require './spec/onapp/installer_cp/shared_examples/installer_cp'

describe 'Install CP + MariaDB ->' do
  before :all do
    @vsa = InstallerCpActions.new.precondition
    @vm = @vsa.virtual_machine
    @version = @vm.get_release_version
    @template = @vsa.template
    @hypervisor = @vsa.hypervisor
    @options = InstallerCp::OPTIONS || '--mariadb'
  end

  after :all do
    if InstallerCpActions::IDENTIFIER
      @vm.rebuild
    else
      @vm.destroy if @vm
      @template.remove if @vm.find_by_template(@template.id).empty?
    end
  end

  let(:vm) { @vsa.virtual_machine }


  include_examples 'VS_is_ok'

  context 'install ->' do
    include_examples 'install'

    it 'Run the Control Panel installer' do
      expect(vm.run_cp_installer(@options)).to be true
    end
  end

  context 'other ->' do
    include_examples 'other'
  end

  context 'MariaDB ->' do
    before :all do
      @db = @vm.load_database_yml
    end

    include_examples 'check_mysql'

    it 'check_rpm_mariadb' do
      expect(vm.check_rpm_mariadb).to be true
    end
  end

  context 'rmq ->' do
    before :all do
      @on_app = @vm.load_on_app_yml
    end

    include_examples 'check_rmq'

    it 'check_rmq_response' do
      expect(vm.check_rmq_response).to be true
    end
  end

  context 'redis ->' do
    include_examples 'check_redis'
  end

  context 'everything is running ->' do
    before :all do
      @db = @vm.load_database_yml
      @on_app = @vm.load_on_app_yml
    end

    include_examples 'everything_is_running'
  end
end


