require 'spec_helper'
require './groups/installer_cp_actions'
require './spec/onapp/installer_cp/shared_examples/installer_cp'

describe 'INSTALLER TESTS(cp + option) ->' do
  before :all do
    @vsa = InstallerCpActions.new.precondition
    @vm = @vsa.virtual_machine
    @version = @vm.get_release_version
    @vm.check_release_version
    @template = @vsa.template
    @hypervisor = @vsa.hypervisor

    MYSQL_HOST    = 'localhost'.freeze
    MYSQL_PORT    = Faker::Number.between(3307, 3507).freeze
    MYSQL_PASSWD  = Faker::Internet.password.freeze
    MYSQL_DB      = Faker::Internet.domain_word.freeze
    MYSQL_USER    = 'root'.freeze

    REDIS_HOST    = 'localhost'.freeze
    REDIS_PORT    = Faker::Number.between(3508, 3708).freeze
    REDIS_PASSWD  = Faker::Internet.password.freeze
    REDIS_BIND    = @vm.ip_address

    RBTHOST       = 'localhost'.freeze
    VCDVHOST      = Faker::Internet.domain_word.freeze
    VCDLOGIN      = Faker::Internet.domain_word.freeze
    VCDPASSWD     = Faker::Internet.password.freeze
    RBTLOGIN      = Faker::Internet.domain_word.freeze
    RBTPASSWD     = Faker::Internet.password.freeze

    PASSWORD_UI   = Faker::Internet.password.freeze
    FIRST_NAME_UI = Faker::Name.first_name.freeze
    LAST_NAME_UI  = Faker::Name.last_name.freeze
    EMAIL_UI      = Faker::Internet.email.freeze

    @options = InstallerCp::OPTIONS || "-m #{MYSQL_HOST} --mysql-port='#{MYSQL_PORT}' -p '#{MYSQL_PASSWD}' -d '#{MYSQL_DB}' -u '#{MYSQL_USER}' \\
                                        --redis-host='#{REDIS_HOST}' --redis-port='#{REDIS_PORT}' --redis-passwd='#{REDIS_PASSWD}' --redis-bind #{REDIS_BIND} \\
                                        --rbthost #{RBTHOST} --vcdvhost /#{VCDVHOST} --vcdlogin #{VCDLOGIN} --vcdpasswd #{VCDPASSWD} \\
                                        --rbtlogin #{RBTLOGIN} --rbtpasswd #{RBTPASSWD} \\
                                        -P '#{PASSWORD_UI}' -F '#{FIRST_NAME_UI}' -L '#{LAST_NAME_UI}' -E '#{EMAIL_UI}'"
  end

  after :all do
    # if InstallerCpActions::IDENTIFIER
    #   @vm.rebuild
    # else
    #   @vm.destroy if @vm
    #   @template.remove if @vm.find_by_template(@template.id).empty?
    # end
  end

  let(:vm) { @vsa.virtual_machine }

  include_examples 'VS_is_ok'


  context 'install ->' do
    include_examples 'install'

    it 'Run the Control Panel installer' do
      expect(vm.run_cp_installer(@options)).to be true

      Log.info("Plase wait... (3 minutes)".white)
      sleep 120
    end
  end

  context 'other ->' do
    include_examples 'other'
  end

  context 'mysql ->' do
    before :all do
      @db = @vm.load_database_yml
    end

    it 'check_mysql_host' do
      expect(@db['production']['host']).to eq MYSQL_HOST
    end

    it 'check_mysql_port' do
      expect(@db['production']['port']).to eq MYSQL_PORT
    end

    it 'check_mysql_passwd' do
      expect(@db['production']['password']).to eq MYSQL_PASSWD
    end

    it 'check_mysql_db' do
      expect(@db['production']['database']).to eq MYSQL_DB
    end

    it 'check_mysql_user' do
      expect(@db['production']['username']).to eq MYSQL_USER
    end

    it 'check_connection_to_db' do
      expect(vm.get_exit_code("mysql -e 'exit' -u #{MYSQL_USER} -p'#{MYSQL_PASSWD}' -h #{MYSQL_HOST} -P #{MYSQL_PORT} #{MYSQL_DB}; echo $?")).to eq true
    end
  end

  context 'redis ->' do
    before :all do
      @redis = @vm.load_redis_yml
    end

    it 'check_redis_host' do
      expect(@redis['production'][:host]).to eq REDIS_HOST
    end

    it 'check_redis_port' do
      expect(@redis['production'][:port]).to eq REDIS_PORT
    end

    it 'check_redis_password' do
      expect(@redis['production'][:password]).to eq REDIS_PASSWD
    end

    it 'check_redis_bind' do
      expect(vm.compare_value('^# bind', '/etc/redis.conf', 'bind')).to eq true
    end

    it 'check_connection_to_redis' do
      expect(vm.get_exit_code("redis-cli -h #{REDIS_HOST} -p #{REDIS_PORT} -a '#{REDIS_PASSWD}' ping")).to eq true
      expect(vm.get_exit_code("redis-cli -h #{vm.ip_address} -p #{REDIS_PORT} -a '#{REDIS_PASSWD}' ping")).to eq true
    end
  end

  context 'rmq ->' do
    before :all do
      @on_app = @vm.load_on_app_yml
    end

    it 'check_rbthost' do
      expect(@on_app['rabbitmq_host']).to eq RBTHOST
    end

    it 'check_vcdvhost' do
      expect(@on_app['rabbitmq_vhost']).to eq "/#{VCDVHOST}"
    end

    it 'check_vcdlogin' do
      expect(@on_app['rabbitmq_login']).to eq VCDLOGIN
    end

    it 'check_vcdpasswd' do
      expect(@on_app['rabbitmq_password']).to eq VCDPASSWD
    end

    it 'check_rbtlogin' do
      expect(vm.compare_value('/onapp/onapp-rabbitmq/.rabbitmq.mgr', RBTLOGIN, column: 1)).to eq true
    end

    it 'check_rbtpasswd' do
      expect(vm.compare_value('/onapp/onapp-rabbitmq/.rabbitmq.mgr', RBTPASSWD)).to eq true
    end

    it 'check_connection_to_rmq(api)' do
      expect(vm.get_exit_code("curl -X GET -u #{RBTLOGIN}:#{RBTPASSWD} http://#{RBTHOST}:15672/api/users | grep -qwi '#{VCDLOGIN}'; echo $?")).to eq true
    end
  end

  context 'everything is running' do
    it 'check_onapp_engine_status' do
      expect(vm.check_onapp_engine_status).to be true
    end

    it 'check_onapp_vnc_proxy' do
      expect(vm.check_onapp_vnc_proxy).to be true
    end

    it 'check_crond_status' do
      expect(vm.check_crond_status).to be true
    end

    it 'check_monit_status' do
      expect(vm.check_monit_status).to be true
    end

    it 'check API availability' do
      expect(vm.get_exit_code("curl -I -X GET -u admin:#{PASSWORD_UI} http://#{vm.ip_address}/users.json; echo $?")).to eq true
    end
  end
end