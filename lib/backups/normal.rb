require 'helpers/onapp_http'
require 'backups/backup_base'

class Normal < BackupBase
  include OnappHTTP
  attr_accessor :id, :type

  def get_normal
    response = get("/settings/configuration")
    return response['settings']
  end

  def get_disk_backups
    response = get("/settings/configuration")
    return response['settings']
  end

  def create(disk_id=nil)
    params = {}
    params[:backup] = data
    response = post("/settings/disks/#{disk_id}/backups", params)
    @id = response['backups']['id']
    @type = response['backups']['backup_type']
    wait_for_transaction(@id, 'Backup', 'take_backup')
  end
end