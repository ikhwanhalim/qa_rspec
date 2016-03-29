class Settings
  attr_reader :interface, :allow_incremental_backups

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
  end

  def reset_to_primary
    interface.put('/settings', {restart: 1, configuration: @primary})
  end
end