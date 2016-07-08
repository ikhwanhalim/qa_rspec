class FederationTrader
  include ApiClient, Waiter, SshClient

  attr_accessor :subscribed_zone, :vm, :template_store
  attr_reader :federation, :template, :hypervisor

  alias get_all get

  def initialize(federation)
    @federation = federation
    conn.cookie_jar.clear!
  end

  def interface
    self
  end

  def subscribe(federation_id)
    data = {
      'hypervisor_zone_namer' => {
        'hypervisor_group_label' => federation_id,
        'hypervisor_label' => federation_id,
        'data_store_group_label' => federation_id,
        'data_store_label' => federation_id,
        'network_group_label' => federation_id,
        'network_label' => federation_id,
        'image_template_group_label' => federation_id
      }
    }
    response = post("/federation/hypervisor_zones/#{federation_id}/subscribe", data)
    if @conn.page.code == '422'
      Log.warn(response)
      return response
    end
    @subscribed_zone = all_subscribed.detect { |z| z.federation_id == federation_id }
    template_store
  end

  def template_store
    get_all('/template_store').detect { |ts| ts.label ==  @subscribed_zone.federation_id}
  end

  def find_hypervisor(label)
    get('/settings/hypervisors').detect {|h| h.hypervisor.label == label}.hypervisor
  end

  def find_template(label)
    template_store.relations.detect {|r| r.image_template.label == label}.image_template
  end

  def search(label)
    zones = get("/federation/hypervisor_zones/unsubscribed/per_page/100", data={q: label})
    zones.map! &:hypervisor_zone
  end

  def all_unsubscribed
    zones = get "/federation/hypervisor_zones/unsubscribed/per_page/100"
    zones.map! &:hypervisor_zone
  end

  def zone_appeared?(federation_id)
    return unless clear_cache
    wait_until do
      !!all_unsubscribed.detect { |z| z.federation_id == federation_id }
    end
  end

  def zone_disappeared?(federation_id)
    return unless clear_cache
    wait_until do
      !all_unsubscribed.detect { |z| z.federation_id == federation_id }
    end
  end

  def all_subscribed
    zones = get "/settings/hypervisor_zones"
    zones.map { |z| z.hypervisor_group if z.hypervisor_group.traded}.compact
  end

  def unsubscribe_all
    errors = ''
    all_subscribed.each do |z|
      response = delete("/federation/hypervisor_zones/#{z.id}/unsubscribe")
      errors << "Zone #{z.id} has not been removed. " if response['errors']
      next
    end
    Log.error(errors) unless errors.empty?
  end

  # VM operations
  def create_vm(template_label)
    hypervisor_id = find_hypervisor(subscribed_zone.federation_id).id
    template_id = find_template(template_label).id
    @template = ImageTemplate.new(self)
    template.find_by_id(template_id)
    @hypervisor = Hypervisor.new(self)
    hypervisor.find_by_id(hypervisor_id)
    @vm = VirtualServer.new(self)
    vm.create
  end


  #Tokens
  def use_token(sender, token)
    data = {token: {token: token, sender: sender}}
    post("/federation/trader_tokens", data)
  end

  #Announcements
  def find_announcement(market_id)
    wait_until do
      announcement = all_announcements.detect { |a| a.announcement.federation_id == market_id }
      announcement ? announcement : false
    end
  end

  def all_announcements
    get("/federation/hypervisor_zones/#{subscribed_zone.id}/announcements")
  end

  def announcement_removed?(announcement)
    wait_until do
      !all_announcements.include?(announcement)
    end
  end

  def edit_announcement(id, text)
    data = {announcement: {text: text}}
    put("/federation/hypervisor_zones/#{subscribed_zone.id}/announcements/#{id}", data)
  end

  def clear_cache
    command = SshCommands::OnControlPanel.remove_federation_cache
    run_on_cp(command)
  end
end
