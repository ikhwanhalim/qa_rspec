class InstallerCp < VirtualServer
  OPTIONS = ENV['OPTIONS']   # default_cp                      = 'nil'
                             # cp_maria_db                     = '--mariadb'
                             # cp_percona                      = '--percona'
                             # cp_percona_cluster              = '--percona-cluster'
                             # cp_no_services_specific_version = '--noservices -v 5.0.0-72'  https://docs.onapp.com/display/RN/Updates+and+Packages'+Versions
  REPO_VERSION = ENV['REPO_VERSION'] || '5.5'

  def ssh_execute(script, with_pass=false)
    cred = {
        'vm_host' => ip_address,
        'vm_pass' => initial_root_password
    }

    interface.execute_with_pass(cred, script)
  end

  def check_inet
    ssh_execute(SshCommands::OnVirtualServer.check_inet)
  end

  def get_exit_code(action)
    return ssh_execute(action).last.to_i.zero?
    Thread.kill(@waiter) # if @waiter
  end

  def waiter(action, interval = 60)
    @waiter = Thread.new {
                            loop do
                              Log.info("Please wait, #{action}".white)
                              sleep interval.to_i

                              pid = ssh_execute("ps aux |  grep -v awk |awk '/root@notty/ {print $2}'").first
                              if installed?
                                if calc_time_of_pid(pid) > 30
                                  Log.info("Looks like onapp-cp-install.sh is stuck".white)
                                  Log.info("The CP is being installed > 30 minutes".white)
                                  Log.info("So we will pid of ssh connection(#{pid})".white)
                                  kill_pid(pid)
                                end

                                Log.info("looks like CP is installed successfully".white)
                                Log.info("but let's give a chance script to close the ssh connection itself".white)
                                Log.info("otherwise PID(#{pid}) of the connection will be killed when time of pid(ps -p PID -o etime=) is reached > 30 min".white)
                              end
                            end
                          }
  end

  def get_pid_of_opened_connection
    ssh_execute("ps aux |  grep -v awk |awk '/root@notty/ {print $2}'").first
  end

  def installed?
    get_exit_code("grep -iq 'Finished Control Panel' /root/onapp-cp-install.log; echo $?")
  end

  def kill_pid(pid)
    ssh_execute("kill -9 #{pid}")
  end

  def calc_time_of_pid(pid)
    ssh_execute("ps -p #{pid} -o etime=".split(':')).first.to_i
  end


  def get_release_version
    ssh_execute(SshCommands::OnVirtualServer.get_release_version).first.to_i
  end

  def check_release_version
    version = get_release_version
    if (6..7).include? version
      Log.info("VS is running under RHEL #{version}.x version".white)
    else
      Log.error("VS is NOT running under RHEL 6.x/7.x version".white)
    end
  end

  def download_repository
    get_exit_code(SshCommands::OnVirtualServer.download_repository)
  end

  def install_cp_installer
    get_exit_code(SshCommands::OnVirtualServer.install_cp_installer)
  end

  def run_cp_installer(options = nil)
    waiter('the \'onapp-cp-install.sh\' script is being installed')
    get_exit_code(SshCommands::OnVirtualServer.run_cp_installer(ip_address, options))
  end

  def check_snmptrap_address(ip_address)
    get_exit_code(SshCommands::OnVirtualServer.check_snmptrap_address(ip_address))
  end

  def check_on_app_owner
    get_exit_code(SshCommands::OnVirtualServer.check_on_app_owner)
  end

  def check_on_app_group
    get_exit_code(SshCommands::OnVirtualServer.check_on_app_group)
  end

  def check_onapp_cp_rpm(version)
    get_exit_code(SshCommands::OnVirtualServer.check_onapp_cp_rpm(version))
  end

  def load_on_app_yml
    YAML::load_stream(ssh_execute(SshCommands::OnVirtualServer.cat_on_app_yml).join("\n"))[0]
  end

  ##############
  ####MYSQL#####
  ##############

  def load_database_yml
    YAML::load_stream(ssh_execute(SshCommands::OnVirtualServer.cat_database_yml).join("\n"))[0]
  end

  def check_mysql_rpm
    get_exit_code(SshCommands::OnVirtualServer.check_mysql_rpm)
  end

  def check_mysql_conf_file
    get_exit_code(SshCommands::OnVirtualServer.check_mysql_conf_file)
  end

  def check_mysql_onapp_init
    get_exit_code(SshCommands::OnVirtualServer.check_mysql_onapp_init)
  end

  def check_onapp_db_folder
    get_exit_code(SshCommands::OnVirtualServer.check_onapp_db_folder)
  end

  def check_owner_db_yml
    get_exit_code(SshCommands::OnVirtualServer.check_owner_db_yml)
  end

  def check_group_db_yml
    get_exit_code(SshCommands::OnVirtualServer.check_group_db_yml)
  end

  def check_conf_mysql_file
    get_exit_code(SshCommands::OnVirtualServer.check_conf_mysql_file)
  end

  def check_dbdpersist_http
    get_exit_code(SshCommands::OnVirtualServer.check_dbdpersist_http)
    end

  def check_dbdexptime_http
    get_exit_code(SshCommands::OnVirtualServer.check_dbdexptime_http)
  end

  def check_dbdmax_http
    get_exit_code(SshCommands::OnVirtualServer.check_dbdmax_http)
  end

  def check_dbdmin_http
    get_exit_code(SshCommands::OnVirtualServer.check_dbdmin_http)
  end

  ##############
  ###RABBITMQ###
  ##############

  def check_rmq_rpm_admin
    get_exit_code(SshCommands::OnVirtualServer.check_rmq_rpm_admin)
  end

  def check_rmq_rpm_cp
    get_exit_code(SshCommands::OnVirtualServer.check_rmq_rpm_cp)
  end

  def check_rmq_rpm_server
    get_exit_code(SshCommands::OnVirtualServer.check_rmq_rpm_server)
  end

  def check_rmq_folder
    get_exit_code(SshCommands::OnVirtualServer.check_rmq_folder)
  end

  def check_rmq_init_onapp
    get_exit_code(SshCommands::OnVirtualServer.check_rmq_init_onapp)
  end

  def check_rmq_init
    get_exit_code(SshCommands::OnVirtualServer.check_rmq_init)
  end

  def check_rmq_response
    get_exit_code(SshCommands::OnVirtualServer.check_rmq_response)
  end

  def check_rmq_main_log_file
    get_exit_code(SshCommands::OnVirtualServer.check_rmq_main_log_file(hostname))
  end

  def check_rmq_shutdown_err
    get_exit_code(SshCommands::OnVirtualServer.check_rmq_shutdown_err)
  end

  def check_rmq_shutdown_log
    get_exit_code(SshCommands::OnVirtualServer.check_rmq_shutdown_log)
  end

  def check_rmq_startup_err
    get_exit_code(SshCommands::OnVirtualServer.check_rmq_startup_err)
  end

  def check_rmq_startup_log
    get_exit_code(SshCommands::OnVirtualServer.check_rmq_startup_log)
  end

  def check_rmq_mgr_file
    get_exit_code(SshCommands::OnVirtualServer.check_rmq_mgr_file)
  end

  ##############
  ####REDIS#####
  ##############

  def load_redis_yml
    YAML::load_stream(ssh_execute(SshCommands::OnVirtualServer.cat_redis_yml).join("\n"))[0]
  end

  def check_redis_rpm_cp
    get_exit_code(SshCommands::OnVirtualServer.check_redis_rpm_cp)
  end

  def check_redis_rpms
    get_exit_code(SshCommands::OnVirtualServer.check_redis_rpms)
  end

  def check_redis_rubygem_rails
    get_exit_code(SshCommands::OnVirtualServer.check_redis_rubygem_rails)
  end

  def check_redis_rubygem_store
    get_exit_code(SshCommands::OnVirtualServer.check_redis_rubygem_store)
  end

  def check_redis_rubygem_redis
    get_exit_code(SshCommands::OnVirtualServer.check_redis_rubygem_redis)
  end

  def check_redis_rubygem_actionpack
    get_exit_code(SshCommands::OnVirtualServer.check_redis_rubygem_actionpack)
  end

  def check_redis_rubygem_activesupport
    get_exit_code(SshCommands::OnVirtualServer.check_redis_rubygem_activesupport)
  end

  def check_redis_rubygem_objects
    get_exit_code(SshCommands::OnVirtualServer.check_redis_rubygem_objects)
  end

  def check_redis_init
    get_exit_code(SshCommands::OnVirtualServer.check_redis_init)
  end

  def check_redis_sentinel_init
    get_exit_code(SshCommands::OnVirtualServer.check_redis_sentinel_init)
  end

  def check_redis_init_onapp
    get_exit_code(SshCommands::OnVirtualServer.check_redis_init_onapp)
  end

  def check_redis_sentinel_onapp
    get_exit_code(SshCommands::OnVirtualServer.check_redis_sentinel_onapp)
  end

  def check_redis_yml
    get_exit_code(SshCommands::OnVirtualServer.check_redis_yml)
  end

  def check_redis_yml_owner
    get_exit_code(SshCommands::OnVirtualServer.check_redis_yml_owner)
  end

  def check_redis_yml_group
    get_exit_code(SshCommands::OnVirtualServer.check_redis_yml_group)
  end

  def check_redis_conf
    get_exit_code(SshCommands::OnVirtualServer.check_redis_conf)
  end

  def check_redis_sentinel_conf
    get_exit_code(SshCommands::OnVirtualServer.check_redis_sentinel_conf)
  end

  def check_redis_folder
    get_exit_code(SshCommands::OnVirtualServer.check_redis_folder)
  end

  def check_redis_onapp_rdb
    name_redis_db = ssh_execute(SshCommands::OnVirtualServer.get_name_redis_rdb)
    get_exit_code(SshCommands::OnVirtualServer.check_redis_onapp_rdb(name_redis_db))
  end

  def check_redis_bind
    get_exit_code(SshCommands::OnVirtualServer.check_redis_bind)
  end
  
  def check_redis_port
    get_exit_code(SshCommands::OnVirtualServer.check_redis_port)
  end

  def check_redis_pidfile_path
    get_exit_code(SshCommands::OnVirtualServer.check_redis_pidfile_path)
  end

  ##########################################
  ###make sure that everything is running###
  ##########################################

  def check_onapp_engine_status
    get_exit_code("service onapp-engine status | grep -q running; echo $?")
  end

  def check_onapp_vnc_proxy
    get_exit_code("service onapp-vnc-proxy status | grep -q running; echo $?")
  end

  def check_crond_status
    get_exit_code("service crond status | grep -q running; echo $?")
  end

  def check_monit_status
    get_exit_code("service monit status | grep -q running; echo $?")
  end

  def check_connection_to_db(username, password, host, port, db)
    get_exit_code(SshCommands::OnVirtualServer.check_connection_to_db(username, password, host, port, db))
  end

  def check_connection_to_rmq(host, vcd_login)
    rbt_login = ssh_execute(SshCommands::OnVirtualServer.get_rbt_login).first
    rbt_password = ssh_execute(SshCommands::OnVirtualServer.get_rbt_password).first

    get_exit_code(SshCommands::OnVirtualServer.check_connection_to_rmq(rbt_login, rbt_password, host, vcd_login))
  end

  def check_connection_to_redis
    path = ssh_execute(SshCommands::OnVirtualServer.get_path_to_redis).first
    get_exit_code(SshCommands::OnVirtualServer.check_connection_to_redis(path))
  end

  def check_api_availability
    get_exit_code(SshCommands::OnVirtualServer.check_api_availability(ip_address))
  end

  ##############
  ###Mariadb####
  ##############
  def check_rpm_mariadb
    get_exit_code(SshCommands::OnVirtualServer.check_rpm_mariadb)
  end

  ##########################
  ###Percona and cluster####
  ##########################

  def check_rpm_percona
    get_exit_code(SshCommands::OnVirtualServer.check_rpm_percona)

  end

  def check_rpm_percona_cluster
    get_exit_code(SshCommands::OnVirtualServer.check_rpm_percona_cluster)
  end

  ##########++ CentOS_7 ++##############################################################################################

  def download_repository_c7
    get_exit_code(SshCommands::OnVirtualServer.download_repository_c7(REPO_VERSION))
  end

  def check_redis_service_c7
    get_exit_code(SshCommands::OnVirtualServer.check_redis_service_c7)
  end

  def check_redis_sentinel_service_c7
    get_exit_code(SshCommands::OnVirtualServer.check_redis_sentinel_service_c7)
  end

  ##############
  ####MYSQL#####
  ##############

  def check_db_is_percona_c7
    get_exit_code(SshCommands::OnVirtualServer.check_db_is_percona_c7)
  end

  def check_db_is_percona_cluster_c7
    get_exit_code(SshCommands::OnVirtualServer.check_db_is_percona_cluster_c7)
  end

##########++ OPTIONS ++##############################################################################################

  def compare_value(grep_pattern=nil, path_to_file, expected_value, column: 2)
    get_exit_code("awk '/#{grep_pattern}/ {print $#{column}}' #{path_to_file} | grep -qw '#{expected_value}'; echo $?")
  end
end
