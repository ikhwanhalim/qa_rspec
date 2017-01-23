class Backup
  include BackupOperationsWaiters
  attr_reader :interface, :id

  #obj can be VM or disk
  def initialize(obj)
    @interface = obj.interface
    @obj_route = obj.route
  end

  def create
    data = interface.post("#{@obj_route}/backups", { backup: { note: '' }} )
    return data['errors'] if interface.conn.page.code != '201'
    info_update(data)
    incremental_allowed? ? wait_for_take_incremental_backup : wait_for_take_backup
    self
  end

  def incremental_allowed?
    interface.settings.allow_incremental_backups
  end

  def info_update(info=false)
    info ||= interface.get(@route)
    info.backup.each { |k,v| instance_variable_set("@#{k}", v) }
    @route = "/backups/#{id}"
    self
  end

  def restore
    interface.post("#{@route}/restore")
    incremental_allowed? ? wait_for_restore_incremental_backup : wait_for_restore_backup
  end

  def convert(**params)
    data = convert_params.merge(params)
    interface.post("#{@route}/convert", { image_template: data })
    wait_for_convert_backup
    interface.template.find_by_label(data[:label])
  end

  def convert_params
    {
        label: "Template-Backup-#{id}",
        min_memory_size: interface.template.min_memory_size,
        min_disk_size: interface.template.min_disk_size
    }
  end

  def remove
    interface.delete @route
    wait_for_destroy_backup
  end
end
