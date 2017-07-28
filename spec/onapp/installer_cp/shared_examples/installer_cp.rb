shared_examples_for 'install' do
  it 'download repository' do
    expect(vm.download_repository).to be true if @version == 6
    expect(vm.download_repository_c7).to be true if @version == 7
  end

  it 'Install OnApp Control Panel installer package' do
    expect(vm.install_cp_installer).to be true
  end
end

shared_examples_for 'check_mysql' do
  it 'check_mysql_conf_file' do
    expect(vm.check_mysql_conf_file).to be true
  end

  it 'check_mysql_onapp_init' do
    expect(vm.check_mysql_onapp_init).to be true if @version == 6
  end

  it 'check_onapp_db_folder' do
    expect(vm.check_onapp_db_folder).to be true
  end

  it 'check_database_db_yml' do
    expect(@db['production']['database']).to eq 'onapp'
  end

  it 'check_reconnect_db_yml' do
    expect(@db['production']['reconnect']).to eq 'true'
  end

  it 'check_password_db_yml' do
    expect(@db['production']['password'].present?).to be true
  end

  it 'check_port_db_yml' do
    expect(@db['production']['port']).to eq 3306
  end

  it 'check_host_db_yml' do
    expect(@db['production']['host']).to eq 'localhost'
  end

  it 'check_socket_db_yml' do
    expect(@db['production']['socket']).to eq '/var/lib/mysql/mysql.sock'
  end

  it 'check_username_db_yml' do
    expect(@db['production']['username']).to eq 'root'
  end

  it 'check_wait_timeout_db_yml' do
    expect(@db['production']['wait_timeout']).to eq 15
  end

  it 'check_owner_db_yml' do
    expect(vm.check_owner_db_yml).to be true
  end

  it 'check_group_db_yml' do
    expect(vm.check_group_db_yml).to be true
  end

  it 'check_conf_mysql_file' do
    expect(vm.check_conf_mysql_file).to be true
  end

  it 'check_dbdpersist_http' do
    expect(vm.check_dbdpersist_http).to be true
  end

  it 'check_dbdexptime_http' do
    expect(vm.check_dbdexptime_http).to be true
  end

  it 'check_dbdmax_http' do
    expect(vm.check_dbdmax_http).to be true
  end

  it 'check_dbdmin_http' do
    expect(vm.check_dbdmin_http).to be true
  end
end

shared_examples_for 'check_rmq' do
  it 'check_rmq_rpm_admin' do
    expect(vm.check_rmq_rpm_admin).to be true
  end

  it 'check_rmq_rpm_cp' do
    expect(vm.check_rmq_rpm_cp).to be true
  end

  it 'check_rmq_rpm_server' do
    expect(vm.check_rmq_rpm_server).to be true
  end

  it 'check_rmq_folder' do
    expect(vm.check_rmq_folder).to be true
  end

  it 'check_rmq_init_onapp' do
    expect(vm.check_rmq_init_onapp).to be true
  end

  it 'check_rmq_init' do
    expect(vm.check_rmq_init).to be true
  end

  it 'check_rmq_login' do
    expect(@on_app['rabbitmq_login']).to eq 'rbtvcd'
  end

  it 'check_rmq_vhost' do
    expect(@on_app['rabbitmq_vhost']).to eq '/'
  end

  it 'check_rmq_host' do
    expect(@on_app['rabbitmq_host']).to eq '127.0.0.1'
  end

  it 'check_rmq_password' do
    expect(@on_app['rabbitmq_password'].present?).to be true
  end

  it 'check_rmq_main_log_file' do
    expect(vm.check_rmq_main_log_file).to be true
  end

  it 'check_rmq_shutdown_err' do
    expect(vm.check_rmq_shutdown_err).to be true
  end

  it 'check_rmq_shutdown_log' do
    expect(vm.check_rmq_shutdown_log).to be true
  end

  it 'check_rmq_startup_err' do
    expect(vm.check_rmq_startup_err).to be true
  end

  it 'check_rmq_startup_log' do
    expect(vm.check_rmq_startup_log).to be true
  end

  it 'check_rmq_mgr_file' do
    expect(vm.check_rmq_mgr_file).to be true
  end
end

shared_examples_for 'check_redis' do
  it 'check_redis_rpm_cp' do
    expect(vm.check_redis_rpm_cp).to be true
  end

  it 'check_redis_rpms' do
    expect(vm.check_redis_rpms).to be true
  end

  it 'check_redis_rubygem_rails' do
    expect(vm.check_redis_rubygem_rails).to be true
  end

  it 'check_redis_rubygem_rails' do
    expect(vm.check_redis_rubygem_rails).to be true
  end

  it 'check_redis_rubygem_store' do
    expect(vm.check_redis_rubygem_store).to be true
  end

  it 'check_redis_rubygem_objects' do
    expect(vm.check_redis_rubygem_objects).to be true
  end

  it 'check_redis_init' do
    expect(vm.check_redis_init).to be true if @version == 6
    expect(vm.check_redis_service_c7).to be true if @version == 7
  end

  it 'check_redis_sentinel_init' do
    expect(vm.check_redis_sentinel_init).to be true if @version == 6
    expect(vm.check_redis_sentinel_service_c7).to be true if @version == 7
  end

  it 'check_redis_init_onapp' do
    expect(vm.check_redis_init_onapp).to be true
  end

  it 'check_redis_sentinel_onapp' do
    expect(vm.check_redis_sentinel_onapp).to be true
  end

  it 'check_redis_yml' do
    expect(vm.check_redis_yml).to be true
  end

  it 'check_redis_yml_owner' do
    expect(vm.check_redis_yml_owner).to be true
  end

  it 'check_redis_yml_group' do
    expect(vm.check_redis_yml_group).to be true
  end

  it 'check_redis_conf' do
    expect(vm.check_redis_conf).to be true
  end

  it 'check_redis_conf' do
    expect(vm.check_redis_conf).to be true
  end

  it 'check_redis_sentinel_conf' do
    expect(vm.check_redis_sentinel_conf).to be true
  end

  it 'check_redis_folder' do
    expect(vm.check_redis_folder).to be true
  end

  it 'check_redis_onapp_rdb' do
    expect(vm.check_redis_onapp_rdb).to be true
  end

  it 'check_redis_bind' do
    expect(vm.check_redis_bind).to be true
  end

  it 'check_redis_port' do
    expect(vm.check_redis_port).to be true
  end

  it 'check_redis_pidfile_path' do
    expect(vm.check_redis_pidfile_path).to be true
  end
end

shared_examples_for 'everything_is_running' do
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

  it 'check_availability' do
    expect(vm.check_api_availability).to eq true
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

shared_examples_for 'other' do
  #TODO think where would be better to put these tests

  it 'check_snmptrap_address' do
    expect(vm.check_snmptrap_address(vm.ip_address)).to be true
  end

  it 'check_on_app_owner' do
    expect(vm.check_on_app_owner).to be true
  end

  it 'check_on_app_group' do
    expect(vm.check_on_app_group).to be true
  end
end

shared_examples_for 'VS_is_ok' do
  it 'make sure VS is ok' do
    expect(vm.pinged?).to be true
    expect(vm.exist_on_hv?).to be true
    expect(vm.ssh_execute(SshCommands::OnVirtualServer.domain, true)).to include vm.domain
  end
end