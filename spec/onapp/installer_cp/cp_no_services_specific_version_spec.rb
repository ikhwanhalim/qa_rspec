require 'spec_helper'
require './groups/installer_cp_actions'
require './spec/onapp/installer_cp/shared_examples/installer_cp'

describe 'INSTALLER TESTS(CP + no_services and specific_version) ->' do
  before :all do
    @vsa = InstallerCpActions.new.precondition
    @vm = @vsa.virtual_machine
    @version = @vm.get_release_version
    @vm.check_release_version
    @template = @vsa.template
    @hypervisor = @vsa.hypervisor
    @options = InstallerCp::OPTIONS || '--noservices -v 5.0.0-72' if @version == 6
    @options = InstallerCp::OPTIONS || '--noservices -v 5.3.0-41' if @version == 7
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

    it 'check_onapp_cp_rpm' do
      expect(vm.check_onapp_cp_rpm(@options.split(' ').last)).to be true
    end
  end

  context 'db ->' do
    before :all do
      @db = @vm.load_database_yml
    end

    include_examples 'check_mysql'

    it 'check rpm' do
      expect(vm.check_mysql_rpm).to be true if @version == 6
      expect(vm.check_rpm_mariadb).to be true if @version == 7
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

  context 'everything is running' do
    before :all do
      @db = @vm.load_database_yml
      @on_app = @vm.load_on_app_yml
    end

    it 'check_onapp_engine_status' do
      expect(vm.check_onapp_engine_status).to be false
    end

    it 'check_onapp_vnc_proxy' do
      expect(vm.check_onapp_vnc_proxy).to be false
    end

    it 'check_crond_status' do
      expect(vm.check_crond_status).to be true
    end

    it 'check_monit_status' do
      expect(vm.check_monit_status).to be false
    end

    it 'check_availability' do
      expect(vm.get_exit_code("curl -I -X GET -u admin:changeme http://#{vm.ip_address}/settings/license.json | grep -q 'Status: 200 OK'; echo $?")).to eq false
    end

    it 'check_connection_to_db' do
      expect(vm.check_connection_to_db(@db['production']['username'], @db['production']['password'], @db['production']['host'], \
                                       @db['production']['port'], @db['production']['database'])).to eq true
    end

    it 'check_connection_to_rmq(api)' do
      expect(vm.check_connection_to_rmq(@on_app['rabbitmq_host'], @on_app['rabbitmq_login'])).to eq true
    end

    it 'check_connection_to_redis' do
      expect(vm.check_connection_to_redis).to eq true
    end
  end
end


