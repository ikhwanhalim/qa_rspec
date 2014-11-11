require 'helpers/transaction'

module Disks  
  include Transaction
    
  def disk_wait_for_build(type)
    disk_id = select_id(type)          
    wait_for_transaction(disk_id, 'Disk', 'build_disk')       
  end  
  def disk_wait_for_provision(type)
    disk_id = select_id(type)          
    wait_for_transaction(disk_id, 'Disk', 'provisioning')        
  end
  
  def select_id(type)
    if type == 'primary'
      disk = (@disks.select { |d| d['disk']['primary'] }).first
    elsif type == 'swap'
      disk = (@disks.select { |d| d['disk']['is_swap'] }).first
    end
    disk['disk']['id']  
  end
end