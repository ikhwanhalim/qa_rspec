require 'helpers/onapp_http'
require 'backups/backup_base'

class Incremental < BackupBase
  include OnappHTTP
  attr_accessor :id, :type

  def get_incremental
    response = get("/virtual_machines/#{vm_id}/backups")
    return response['backups']
  end

  def create(vm_id=nil)
    #params = {}
    #params[:backup] = data
    response = post("/virtual_machines/#{vm_id}/backups")
    puts response
    @id = response['backup']['id']
    @type = response['backup']['backup_type']
    wait_for_transaction(@id, 'Backup', 'take_incremental_backup')
  end
end