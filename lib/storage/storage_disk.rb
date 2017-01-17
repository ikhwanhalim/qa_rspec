class StorageDisk
  include DiskOperationsWaiters, Waiter, Diagnostic
  attr_reader :interface, :id, :name, :size, :data_store, :last_repair_delivery, :parent_id,
              :last_failed_diagnostic, :hypervisor_ip

  def initialize(interface)
    @interface = interface
    @hypervisor_group = interface.hypervisor.hypervisor_group_id
    @hypervisor_id = interface.hypervisor.id
    @hypervisor_ip = interface.hypervisor.ip_address
    @disks_route = "/storage/#{@hypervisor_group}/data_stores/#{get_storage_datastore_id}/disks"
  end

  def get_storage_datastore_id
    interface.get("/storage/#{@hypervisor_group}/data_stores").first.data_store.id
  end

  def get_settings_datastore_id
    interface.get("/settings/data_stores").select do |obj|
      obj.data_store.identifier == get_storage_datastore_id
    end[0].data_store.id
  end

  def get_datastore_autohealing?
    interface.get("/settings/data_stores").reject do |obj|
      obj.data_store.identifier != get_storage_datastore_id
    end[0].data_store.auto_healing
  end

  def get_repair_parent_id
    @parent_id = ((interface.get("/transactions", { page: 1, per_page: 1000 }).reject do |obj|
      obj.transaction.parent_type != "Storage::Repair"
    end.first.transaction.parent_id).to_i + 1)
  end

  def get_last_repair_delivery
    @last_repair_delivery = interface.get("/messaging/deliveries", { page: 1, per_page: 1000 }).reject do |obj|
      obj.messaging_delivery.subscription_name != "Auto healing processing disk repair subscription"
    end.first.messaging_delivery.id
  end

  def get_last_failed_diagnostic_delivery
    @last_failed_diagnostic = interface.get("/messaging/deliveries", { page: 1, per_page: 1000 }).reject do |obj|
      obj.messaging_delivery.subscription_name != "Auto healing failed diagnostics subscription"
    end.first.messaging_delivery.id
  end

  def repair_transaction_wait
    wait_for_repair_vdisk(parent_id)
  end

  def rebalance_transaction_wait
    wait_for_rebalance_vdisk(parent_id)
  end

  def repair_delivery_sent?
    new_delivery = interface.get("/messaging/deliveries", page: 1, per_page: 1000).reject do |obj|
      obj.messaging_delivery.subscription_name != "Auto healing processing disk repair subscription"
    end.first.messaging_delivery.id
    return true if new_delivery > @last_repair_delivery
    return false
  end

  def repair_failed_diagnostic_sent?
    new_delivery = interface.get("/messaging/deliveries", {page: 1, per_page: 1000}).reject do |obj|
      obj.messaging_delivery.subscription_name != "Auto healing failed diagnostics subscription"
    end.first.messaging_delivery.id
    return true if new_delivery > @last_failed_diagnostic
    return false
  end

  def wait_no_pending_transactions
    sleep(60)
    wait_until(1000, 20) do
      Log.info("Wait until no pending transactions present")
      interface.get("/transactions", { page: 1, per_page: 20}).select do |t|
        t if t.transaction.status == "pending"
      end == []
    end
  end

  # VDISK METHODS:



  def execute_vdisks_list
    ssh_execute(SshCommands::OnCloudbootHypervisor.get_vdisks_list)
  end

  def create
    @name = 'vdisk'
    @size = '1024'
    info = interface.post(@disks_route, { storage_disk: { name: name, size: size } })
    info.disk.each { |k,v| instance_variable_set("@#{k}", v) }
    self
  end

  def create_max_vdisk
    @name = 'vdisk'
    @size = max_vdisk_size
    info = interface.post(@disks_route, { storage_disk: { name: name, size: size } })
    info.disk.each { |k,v| instance_variable_set("@#{k}", v) }
    self
  end

  def create_high_utilised_vdisk
    @name = 'vdisk'
    @size = high_utilisation_vdisk_size
    info = interface.post(@disks_route, { storage_disk: { name: name, size: size } })
    info.disk.each { |k,v| instance_variable_set("@#{k}", v) }
    self
  end

  def destroy_all_vdisks
    if ssh_execute(SshCommands::OnCloudbootHypervisor.offline_vdisks(execute_vdisks_list))
      @disk_list = interface.get(@disks_route)
      @disk_list.map { |vdisk| interface.delete("#{@disks_route}/#{vdisk.disk.id}")}
    end
  end

  private

  def ssh_execute(script)
    interface.tunnel_execute({'vm_host' => interface.hypervisor.ip_address}, script)
  end
end