require './lib/helpers/transaction'
require 'helpers/onapp_ssh'

class BackupBase
  include Transaction, OnappHTTP
  attr_accessor :template_from_backup
  def initialize(user=nil)
    if user
      auth(url: @url, user: user.login, pass: user.password)
    elsif !self.conn
      auth unless self.conn
    end
  end

  def get_all_vs_backups(vm_id=nil)
    response = get("/virtual_machines/#{vm_id}/backups")
    return response['backups']
  end

  def convert_to_template(backup_id=nil, data={})
    params = {}
    params[:backup] = data
    response = post("/backups/#{backup_id}/convert", params)
    puts "response - #{response}"
    wait_for_transaction(backup_id, 'Backup', 'convert_backup')
    @template_from_backup = response['image_template']
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


  def size(backup_id=nil)
    response = get("/backups/#{backup_id}")
    return response['backup']['backup_size']
  end

  def on_backup_server?(backup_id=nil)
    response = get("/backups/#{backup_id}")
    return true ? response['backup']['backup_server_id'].class == Fixnum : false
  end
end