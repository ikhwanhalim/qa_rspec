class FederationSupplier
  include ApiClient, TemplateManager, Waiter, SshClient

  attr_accessor :published_zone, :vm, :resources, :hypervisor
  attr_reader :federation, :template

  def initialize(federation)
    @federation = federation
  end

  def interface
    self
  end

  def get_publishing_resources
    hv = Hypervisor.new(self).find_by_virt(ENV['VIRT_TYPE'])
    if hv
      hvz_id = hv.hypervisor_group_id || Log.error("Hypervisor not attached")
      hv_zone = get("/settings/hypervisor_zones/#{hvz_id}").hypervisor_group
      nt_joins = get("/settings/hypervisor_zones/#{hvz_id}/network_joins")
      nt_joins += get("/settings/hypervisors/#{hv.id}/network_joins")
      ds_joins = get("/settings/hypervisor_zones/#{hvz_id}/data_store_joins")
      ds_joins += get("/settings/hypervisors/#{hv.id}/data_store_joins")
      nt = get("/settings/networks/#{nt_joins.first.network_join.network_id}").network
      nt_zone = get("/settings/network_zones/#{nt.network_group_id}").network_group || Log.error("Network not attached")
      ds = get("/settings/data_stores/#{ds_joins.first.data_store_join.data_store_id}").data_store
      ds_zone = get("/settings/data_store_zones/#{ds.data_store_group_id}").data_store_group || Log.error("Data store not attached")
      Log.error("Data store group not in location group") if ds_zone.location_group_id != hv_zone.location_group_id
      Log.error("Network group not in location group") if nt_zone.location_group_id != hv_zone.location_group_id
      return Hashie::Mash.new({'hypervisor_group' => hv_zone,
              'data_store_group' => ds_zone,
              'network_group' => nt_zone
      })
    end
    Log.error "HypervisorGroupNotFound"
  end

  def add_to_federation(private: 0, label: nil)
    @template = ImageTemplate.new(self).find_by_manager_id(ENV['TEMPLATE_MANAGER_ID'])
    @resources ||= get_publishing_resources
    @data_store_group = @resources.data_store_group
    @network_group = @resources.network_group
    @hvz_id = @resources.hypervisor_group.id
    stamp = 'federation-autotest' + DateTime.now.strftime('-%d-%m-%y(%H:%M:%S)')
    data = {
      'hypervisor_zone' => {
        'provider_name' => label || stamp,
        'label' => label || stamp,
        'private' => private,
        'data_store_zone_id' => @data_store_group.id,
        'network_zone_id' => @network_group.id,
        'template_group_id' => @template_store.id,
        'description' => "#{Socket.gethostname}\n#{Socket.ip_address_list.to_s}"
      }
    }
    response = post("/federation/hypervisor_zones/#{@hvz_id}/add", data)
    Log.error(response.values.join("\n")) if response['errors'].any?
    @published_zone = get("/settings/hypervisor_zones/#{@hvz_id}").values.first
    sleep 15 #Wait for TemplateTracker and Zabbix tasks
  end

  def make_public
    put("/federation/hypervisor_zones/#{@hvz_id}/make_public")
  end

  def make_private
    put("/federation/hypervisor_zones/#{@hvz_id}/make_private")
  end

  def disable_zone(id=@published_zone.id)
    @published_zone = post("/federation/hypervisor_zones/#{id}/deactivate").values.first
  end

  def enable_zone(id=@published_zone.id)
    @published_zone = post("/federation/hypervisor_zones/#{id}/activate").values.first
  end

  def remove_from_federation(id=@published_zone.id)
    get_last_transaction_id
    disable_zone(id)
    delete("/federation/hypervisor_zones/#{id}/schedule_unpublish")
    if conn.page.code == '404'
      delete("/federation/hypervisor_zones/#{id}/remove")
    else
      wait_for_transaction(id, "Pack", "clean_federated_zone")
    end
    @published_zone = nil if all_federated.empty?
  end

  def all_federated
    get("/settings/hypervisor_zones").select do |z|
      z.hypervisor_group.federation_id != nil &&
          z.hypervisor_group.supplier_version == nil &&
          z.hypervisor_group.supplier_provider == nil
    end
  end

  def remove_all_from_federation
    all_federated.each { |z| remove_from_federation(z.id) }
  end

  def hypervisors_detach
    id=@published_zone.id
    @hypervisors_ids = get("/settings/hypervisor_zones/#{id}/hypervisors").map { |hv| hv.hypervisor.id }
    post("/settings/hypervisor_zones/#{id}/hypervisors/detach_range", {ids: @hypervisors_ids})
  end

  def hypervisors_attach
    id=@published_zone.id
    post("/settings/hypervisor_zones/#{id}/hypervisors/attach_range", {ids: @hypervisors_ids})
    !!get("/settings/hypervisor_zones/#{id}/hypervisors").any?
  end

  def data_stores_detach
    id = @data_store_group.id
    @data_stores_ids = get("/settings/data_store_zones/#{id}/data_stores").map do |ds|
      ds.data_store.id
    end
    post("/settings/data_store_zones/#{id}/data_stores/detach_range", {ids: @data_stores_ids})
  end

  def data_stores_attach
    id = @data_store_group.id
    post("/settings/data_store_zones/#{id}/data_stores/attach_range", {ids: @data_stores_ids})
    !!get("/settings/data_store_zones/#{id}/data_stores").any?
  end

  # VM operations
  def vm
    @vm ||= -> {
      server = VirtualServer.new(self)
      virtual_machine = server.all.detect do |s|
        vm_primary_ip = s.virtual_machine.ip_addresses.first
        vm_primary_ip && vm_primary_ip.ip_address.address == federation.trader.vm.ip_address
      end.virtual_machine
      server.find(virtual_machine.id)
    }.call
  end

  #Announcements
  def generate_announcement
    data = {
      announcement: {
        text: 'Autotest message',
        start_at: 10.second.from_now,
        finish_at: 1.day.from_now
      }
    }
    post("/federation/hypervisor_zones/#{published_zone.id}/announcements", data)
  end

  def all_announcements
    get("/federation/hypervisor_zones/#{published_zone.id}/announcements")
  end

  def wait_announcement_id(local_id)
    wait_until do
      announcement = all_announcements.detect { |a| a.announcement.id == local_id && a.announcement.federation_id }
      announcement ? announcement : false
    end
  end

  def remove_announcement(local_id)
    delete("/federation/hypervisor_zones/#{published_zone.id}/announcements/#{local_id}")
  end

  #Tokens
  def generate_token(receiver)
    data = {token: {receiver: receiver}}
    post("/federation/hypervisor_zones/#{@hvz_id}/supplier_tokens", data)
  end

  def get_token(receiver)
    wait_until do
      token = get("/federation/hypervisor_zones/#{@hvz_id}/supplier_tokens").detect do |t|
        t.token.receiver == receiver
      end
      token ? token : false
    end
  end

  #Transactions
  def get_last_transaction_id
    @last_transaction_id = get('/transactions', {page: 1, per_page: 10}).first.transaction.id
  end
end
