module ServiceChecker
  SERVICES = %w(httpd mysqld onapp_engine onappd rabbitmq redis-server)

  def check_services
    offline_services = get('/sysadmin_tools/infrastructure/services').first.services.select do |s|
      SERVICES.include?(s.name) && s.status == 'Offline'
    end
    if offline_services.any?
      Log.error("Services #{offline_services.map(&:name)} are Offline")
    else
      Log.info('All service are running')
    end
  end
end