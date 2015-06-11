require './lib/helpers/transaction'

class BackupBase
  include Transaction
  def get_all_vs_backups(vm_id=nil)
    response = get("/virtual_machines/#{vm_id}/backups")
    return response['backups']
  end

  def convert_to_template(backup_id=nil, data={})
    params = {}
    params[:backup] = data
    post("/backups/#{backup_id}/convert", params)
    wait_for_transaction(backup_id, 'Backup', 'convert_backup')
  end

  def restore(backup_id=nil, type=nil)
    post("/backups/#{backup_id}/restore")
    if type == 'normal'
      wait_for_transaction(backup_id, 'Backup', 'restore_backup')
    elsif type == 'incremental'
      wait_for_transaction(backup_id, 'Backup', 'restore_incremental_backup')
    else
      Log.error("Undefined backup type during restoring.")
    end
  end

  def delete(backup_id=nil)
    delete("backups/#{backup_id}")
    wait_for_transaction(backup_id, 'Backup', 'destroy_backup')
  end
end