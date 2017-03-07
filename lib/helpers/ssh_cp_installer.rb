module SshCpInstaller
  def check_inet
    'ping -c1 google.com;echo $?'
  end

  def download_repository
    if ENV['REPO_VERSION']
      "rpm -Uvh http://rpm.repo.onapp.com/repo/onapp-repo-#{ENV['REPO_VERSION']}.noarch.rpm;echo $?"
    else
      'rpm -Uvh http://rpm.repo.onapp.com/repo/onapp-repo.noarch.rpm;echo $?'
    end
  end

  def install_cp_installer
    'yum -y install onapp-cp-install; echo $?'
  end

  def run_cp_installer(ip_address, options = nil)
    "export OPENSSL_ENABLE_MD5_VERIFY=1 && /onapp/onapp-cp-install/onapp-cp-install.sh -a -i #{ip_address} #{options} && service onapp-licensing restart;echo $?"
  end

  def check_snmptrap_address(ip_address)
    "grep -q 'snmptrap_addresses: #{ip_address}' /onapp/interface/config/on_app.yml; echo $?"
  end

  def check_on_app_owner
    "ls -l /onapp/interface/config/on_app.yml | awk '{print $3}' | grep -q 'onapp'; echo $?;"
  end

  def check_on_app_group
    "ls -l /onapp/interface/config/on_app.yml | awk '{print $4}' | grep -q 'onapp'; echo $?;"
  end

  def check_onapp_cp_rpm(version)
    "rpm -q onapp-cp | grep -q 'onapp-cp-#{version}.noarch'; echo $?;"
  end

  def cat_on_app_yml
    'cat /onapp/interface/config/on_app.yml'
  end

  ##############
  ####MYSQL#####
  ##############

  def cat_database_yml
    'cat /onapp/interface/config/database.yml'
  end

  def check_mysql_rpm
    "rpm -qa | grep -q mysql-server; echo $?"
  end

  def check_mysql_conf_file
    "test -f /etc/my.cnf; echo $?"
  end

  def check_mysql_onapp_init
    "test -f /etc/init.d/onapp-db; echo $?"
  end

  def check_onapp_db_folder
    "test -d /var/lib/mysql/; echo $?"
  end

  def check_owner_db_yml
    "ls -l /onapp/interface/config/database.yml  | awk '{print $3}' | grep -q onapp; echo $?"
  end

  def check_group_db_yml
    "ls -l /onapp/interface/config/database.yml  | awk '{print $4}' | grep -q onapp; echo $?"
  end

  def check_conf_mysql_file
    "test -s /etc/my.cnf; echo $?"
  end

  def check_dbdpersist_http
    "grep -q 'DBDPersist   On' /etc/httpd/conf.d/onapp.conf; echo $?"
  end

  def check_dbdexptime_http
    "grep -q 'DBDExptime   300' /etc/httpd/conf.d/onapp.conf; echo $?"
  end

  def check_dbdmax_http
    "grep -q 'DBDMax       10' /etc/httpd/conf.d/onapp.conf; echo $?"
  end

  def check_dbdmin_http
    "grep -q 'DBDMin       1' /etc/httpd/conf.d/onapp.conf; echo $?"
  end

  ##############
  ###RABBITMQ###
  ##############

  def check_rmq_rpm_admin
    "rpm -qa | grep -q rabbitmq-admin; echo $?"
  end

  def check_rmq_rpm_cp
    "rpm -qa | grep -q onapp-cp-rabbitmq; echo $?"
  end

  def check_rmq_rpm_server
    "rpm -qa | grep -q rabbitmq-server; echo $?"
  end

  def check_rmq_folder
    "test -d /var/lib/rabbitmq/; echo $?"
  end

  def check_rmq_init_onapp
    "test -f /etc/init.d/onapp-mq; echo $?"
  end

  def check_rmq_init
    "test -f /etc/init.d/rabbitmq-server; echo $?"
  end

  def check_rmq_response
    "rabbitmqctl list_users; echo $?"
  end

  def check_rmq_main_log_file(hostname)
    "test -f /var/log/rabbitmq/rabbit\\@#{hostname}.log; echo $?"
  end

  def check_rmq_shutdown_err
    "test -f /var/log/rabbitmq/shutdown_err; echo $?"
  end

  def check_rmq_shutdown_log
    "test -f /var/log/rabbitmq/shutdown_log; echo $?"
  end

  def check_rmq_startup_err
    "test -f /var/log/rabbitmq/startup_err; echo $?"
  end

  def check_rmq_startup_log
    "test -f /var/log/rabbitmq/startup_log; echo $?"
  end

  def check_rmq_mgr_file
    "test -f  /onapp/onapp-rabbitmq/.rabbitmq.mgr; echo $?"
  end

  ##############
  ####REDIS#####
  ##############

  def cat_redis_yml
    'cat /onapp/interface/config/redis.yml'
  end

  def check_redis_rpm_cp
    "rpm -qa | grep -q onapp-cp-redis; echo $?"
  end

  def check_redis_rpms
    "rpm -qa | grep -q '^redis'; echo $?"
  end

  def check_redis_rubygem_rails
    "rpm -qa | grep -q rubygem-redis-rails; echo $?"
  end

  def check_redis_rubygem_store
    "rpm -qa | grep -q rubygem-redis-store; echo $?"
  end

  def check_redis_rubygem_redis
    "rpm -qa | grep -q rubygem-redis; echo $?"
  end

  def check_redis_rubygem_actionpack
    "rpm -qa | grep -q rubygem-redis-actionpack; echo $?"
  end

  def check_redis_rubygem_activesupport
    "rpm -qa | grep -q rubygem-redis-activesupport; echo $?"
  end

  def check_redis_rubygem_objects
    "rpm -qa | grep -q rubygem-redis-objects; echo $?"
  end

  def check_redis_init
    "test -f /etc/init.d/redis; echo $?"
  end

  def check_redis_sentinel_init
    "test -f /etc/init.d/redis-sentinel; echo $?"
  end

  def check_redis_init_onapp
    "test -f /etc/init.d/onapp-redis; echo $?"
  end

  def check_redis_sentinel_onapp
    "test -f /etc/init.d/onapp-redis-sentinel; echo $?"
  end

  def check_redis_yml
    "test -f /onapp/interface/config/redis.yml; echo $?"
  end

  def check_redis_yml_owner
    "ls -l  /onapp/interface/config/redis.yml | awk '{print $3}'| grep -q onapp; echo $?"
  end

  def check_redis_yml_group
    "ls -l  /onapp/interface/config/redis.yml | awk '{print $4}'| grep -q onapp; echo $?"
  end

  def check_redis_conf
    "test -f /etc/redis.conf; echo $?"
  end

  def check_redis_sentinel_conf
    "test -f /etc/redis-sentinel.conf; echo $?"
  end

  def check_redis_folder
    "test -d /var/lib/redis/; echo $?"
  end

  def get_name_redis_rdb
    "awk '/^dbfilename/ {print $2}' /etc/redis.conf; echo $?"
  end

  def check_redis_onapp_rdb(name_redis_db)
    "test -f /var/lib/redis/#{name_redis_db}"
  end

  def check_redis_bind
    "grep -q 'bind 127.0.0.1' /etc/redis.conf; echo $?"
  end

  def check_redis_port
    "grep -q '^port 0' /etc/redis.conf; echo $?"
  end

  def check_redis_pidfile_path
    "grep -q 'pidfile /var/run/redis/redis.pid' /etc/redis.conf; echo $?"
  end

  ##########################################
  ###make sure that everything is running###
  ##########################################

  def check_onapp_engine_status
    "service onapp-engine status | grep -q running; echo $?"
  end

  def check_onapp_vnc_proxy
    "service onapp-vnc-proxy status | grep -q running; echo $?"
  end

  def check_crond_status
    "service crond status | grep -q running; echo $?"
  end

  def check_monit_status
    "service monit status | grep -q running; echo $?"
  end

  def check_connection_to_db(username, password, host, port, db)
    "mysql -e 'exit' -u #{username} -p'#{password}' -h #{host} -P #{port} #{db}; echo $?"
  end

  def get_rbt_login
    "awk '{print $1}' /onapp/onapp-rabbitmq/.rabbitmq.mgr"
  end

  def get_rbt_password
    "awk '{print $2}' /onapp/onapp-rabbitmq/.rabbitmq.mgr"
  end

  def check_connection_to_rmq(rbt_login, rbt_password, host, vcd_login)
    "curl -X GET -u #{rbt_login}:\"#{rbt_password}\" http://#{host}:15672/api/users | grep -qwi '#{vcd_login}'; echo $?"
  end

  def get_path_to_redis
    "awk '/path/ {print $2}' /onapp/interface/config/redis.yml"
  end

  def check_connection_to_redis(path)
    "redis-cli -s #{path} ping"
  end

  def check_api_availability(ip_address)
    "curl -I -X GET -u admin:changeme http://#{ip_address}/settings/license.json | grep -q 'Status: 200 OK'; echo $?"
  end

  ##############
  ###Mariadb####
  ##############
  def check_rpm_mariadb
    "rpm -qa | grep -q mariadb; echo $?"
  end

  ##########################
  ###Percona and cluster####
  ##########################

  def check_rpm_percona
    "rpm -qa | grep -q percona-release; echo $?"
  end

  def check_rpm_percona_cluster
    "rpm -qa | grep -q percona-xtrabackup; echo $?"
  end

  ##########++ CentOS_7 ++##############################################################################################

  #TODO check; I think is not used anymore
  def download_repository_c7(repo_version)
    "rpm -Uvh http://rpm.repo.onapp.com/repo/onapp-repo-#{repo_version}.noarch.rpm;echo $?"
  end

  def check_redis_service_c7
    "test -f /usr/lib/systemd/system/redis.service; echo $?"
  end

  def check_redis_sentinel_service_c7
    "test -f /usr/lib/systemd/system/redis-sentinel.service; echo $?"
  end

  ##############
  ####MYSQL#####
  ##############

  def check_db_is_percona_c7
    "service mysqld status | grep -qi 'Percona Server'; echo $?"
  end

  def check_db_is_percona_cluster_c7
    "service mysql status | grep -qi 'Percona XtraDB Cluster'; echo $?"
  end
end