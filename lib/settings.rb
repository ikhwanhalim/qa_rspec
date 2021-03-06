class Settings
  attr_accessor :has_been_changed
  attr_reader :interface, :allow_incremental_backups, :zabbix_host, :delete_template_source_after_install, :allow_initial_root_password_encryption,
              :iso_path_on_hv, :enforce_redundancy, :cloud_boot_enabled, :password_minimum_length, :password_symbols,
              :rabbitmq_host, :rabbitmq_login, :rabbitmq_password, :rabbitmq_port, :rabbitmq_vhost


  alias has_been_changed? has_been_changed

  def initialize(interface)
    @interface = interface
    primary
  end

  def primary
    @primary ||= read
  end

  def read
    interface.get('/settings/configuration').settings.each do |k,v|
      instance_variable_set("@#{k}", v)
    end
  end

  def setup(**params)
    updated = primary.merge(params)
    interface.put('/settings', {restart: 1, configuration: updated})
    @has_been_changed = true
    read
  end

  def reset_to_primary
    interface.put('/settings', {restart: 1, configuration: @primary})
  end

  def generate_password
    #('0'..'z').to_a.shuffle.sample(password_minimum_length).join
    Faker::Internet.password(password_minimum_length) + %w(@ - _ ).sample
  end
end