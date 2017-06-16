shared_examples_for 'power_operations' do
  it { expect(vm.pinged?).to be true }
  it { expect(vm.exist_on_hv?).to be true }
  it { expect(vm.edge_server_type).to eq CdnServer::CDN_SERVER_TYPE } if CdnServer::CDN_SERVER == 'edge_server'
  it { expect(vm.storage_server_type).to eq CdnServer::CDN_SERVER_TYPE } if CdnServer::CDN_SERVER == 'storage_server'

  it 'Stop' do
    vm.stop
    expect(vm.not_pinged?).to be true
  end

  it 'Start' do
    vm.start_up
    expect(vm.pinged? && vm.exist_on_hv?).to be true
  end

  it 'Shutdown' do
    vm.shut_down
    expect(vm.not_pinged?).to be true
  end

  it 'Startup' do
    vm.start_up
    expect(vm.pinged? && vm.exist_on_hv?).to be true
  end

  it 'Reboot' do
    vm.reboot
    expect(vm.pinged? && vm.exist_on_hv?).to be true
  end

  it 'Suspend and try startup(422)' do
    vm.suspend
    expect(vm.not_pinged?).to be true
    expect(vm.exist_on_hv?).to be false
    vm.start_up
    expect(vm.api_response_code).to eq '422'
  end

  it 'Unsuspend and Startup' do
    vm.unsuspend
    expect(vm.down?).to be true
    vm.start_up
    expect(vm.pinged? && vm.exist_on_hv?).to be true
  end
end

shared_examples_for 'network_interfaces' do
  before :all do
    @ids = @vm.available_network_join_ids
    @cp_version = @vma.version
  end

  before do
    skip('Additional network has not been attached to HV or HVZ') if @ids.empty?
  end

  it 'Attach new' do
    skip("this test is not able for accelerator; alternative test should be permormed at the end") if CdnServer::CDN_SERVER == 'accelerator'
    amount = vm.network_interfaces.count
    vm.attach_network_interface
    expect(vm.network_interfaces.count).to eq amount + 1
  end

  it 'Detach' do
    skip("this test is not able for accelerator; alternative test should be permormed at the end") if CdnServer::CDN_SERVER == 'accelerator'
    amount = vm.network_interfaces.count
    vm.network_interface('additional').remove
    expect(vm.network_interfaces.count).to eq amount - 1
  end

  it 'Detach primary network interface and attach again' do
    amount = vm.network_interfaces.count
    ip = vm.ip_address
    vm.network_interface.remove
    expect(vm.network_interfaces.count).to eq amount - 1
    expect(vm.not_pinged?(remote_ip: ip)).to be true
    expect(vm.check_firewall_rules(remote_ip: ip)).to eq 0
    vm.attach_network_interface(primary: true)
    vm.network_interface.allocate_new_ip
    vm.rebuild_network
    expect(vm.pinged?).to be true
    expect(vm.network_interfaces.count).to eq amount
    #TODO expect(vm.check_firewall_rules).to eq 2 skip (CORE-9886)
  end

  it 'Ability to create two primary interfaces should be blocked' do
    amount = vm.network_interfaces.count
    expect(vm.attach_network_interface(existed=false, primary: true)['primary']).to eq(["already has primary allocation."])
    expect(@vma.conn.page.body.errors.network).to eq ["Only one Network allowed per Accelerator"] if CdnServer::CDN_SERVER == 'accelerator'
    expect(vm.network_interfaces.count).to eq amount
  end

  it 'Update port speed' do
    current_port_speed = vm.network_interface.port_speed
    port_speed = case
                   when current_port_speed == 0
                     Faker::Number.between(1, 1000)
                   when current_port_speed >= 501 && current_port_speed <= 1000
                     current_port_speed - Faker::Number.between(1, 400)
                   else
                     current_port_speed + Faker::Number.between(1, 400)
                 end
    vm.network_interface.edit(rate_limit: port_speed)
    expect(vm.network_interface.rate_limit).to eq port_speed
    expect(vm.network_interface.port_speed).to eq port_speed
  end

  it 'Edit network interface' do
    vm.network_interface.edit(label: 'eth1', primary: false)
    expect(vm.network_interface.label).to eq('eth1')
    expect(vm.network_interface.primary).to be false
    vm.network_interface.edit(primary: true)
    expect(vm.network_interface.primary).to be true
  end
end

shared_examples_for 'ip_addresses' do
  before :all do
    @cp_version = @vma.version
    if @cp_version < 5.4
      @vm.network_interface.allocate_new_ip
      @free_addresses = @vm.network_interface.ip_address.all
    else
      @second_ip = @vm.network_interface.ip_address.free_ip
      @vm.network_interface.allocate_new_ip(address: @second_ip)
    end
    @vm.rebuild_network
    @primary_network_interface_exist = @vm.network_interface.any?
  end

  before do
    fail('Primary network interface does not exist') unless @primary_network_interface_exist
    (skip('There are no free ip addresses') if @free_addresses.empty?) if @cp_version < 5.4
  end

  it 'Second IP address should be appeared in the interface' do
    skip ("https://onappdev.atlassian.net/browse/CORE-9886")
    expect(vm.ip_addresses.count).to eq 2
    @second_ip = vm.network_interface.ip_address(2).address if @cp_version < 5.4
    expect(vm.check_firewall_rules(remote_ip: @second_ip)).to eq 2
  end

  it 'All IPs should be pinged' do
    skip ("https://onappdev.atlassian.net/browse/CORE-9886")
    ping_states = vm.ip_addresses.map &:pinged?
    expect(ping_states.include?(false)).to be false
    expect(vm.ip_addresses.map(&:check_firewall_rules)).to match_array([2, 2])
  end

  it 'Remove second IP' do
    amount = vm.ip_addresses.count
    skip("https://onappdev.atlassian.net/browse/CORE-9907") if amount <= 1
    vm.network_interface.remove_ip(2)
    vm.rebuild_network
    expect(vm.ip_addresses.count).to eq amount - 1
    # expect(vm.check_firewall_rules(remote_ip: @second_ip)).to eq 0
    # expect(vm.check_arptables_rules(remote_ip: @second_ip)).to eq 0
  end

  it 'Allocate the same IP should not be allowed' do
    skip ("https://onappdev.atlassian.net/browse/CORE-9886")
    if @cp_version < 5.4
      expect(vm.network_interface.allocate_new_ip(ip_address_id: vm.network_interface.ip_address.id, used_ip: 1)['ip_address_id']).to eq(['is already allocated to this network card'])
    else
      expect(vm.network_interface.allocate_new_ip(used_ip: 1, address: vm.ip_address)['selected_ip_address']).to eq(['is already allocated to this network card'])
    end
    expect(vm.api_response_code).to eq '422'
    expect(vm.ip_addresses.count).to eq 1
    expect(vm.check_firewall_rules).to eq 2
  end

  it 'Remove primary IP' do
    skip("https://onappdev.atlassian.net/browse/CORE-9907")
    primary_ip = vm.ip_address
    vm.network_interface.remove_ip
    vm.rebuild_network
    expect(vm.ip_addresses.count).to eq 0
    expect(vm.check_firewall_rules(remote_ip: primary_ip)).to eq 0
    @vm.network_interface.allocate_new_ip
    expect(vm.ip_addresses.count).to eq 1
  end

  it 'Allocate used IP' do
    #TODO try to improve
    amount = vm.ip_addresses.count
    used_ip_address = []

    unless amount == 0
      used_ips = vm.network_interface.ip_address.user_used_ips(vm)
      used_ip_address = used_ips.sample if used_ips.count >= 1
    end

    if used_ip_address.size == 0
      skip("You have forgotten to set 'TEMPLATE_VM_ID' env variable") unless CdnServerActions::TEMPLATE_VM_ID
      @vm_new = VirtualServer.new(@vma)
      @vm_new.create(template_id: CdnServerActions::TEMPLATE_VM_ID, hypervisor_id: vm.hypervisor_id, label: Faker::Internet.domain_word, \
                         network_id: vm.network_interface.ip_address.ip_net_id)
      skip('VS has not been built. The user has no suitable used IP') unless @vm_new.api_response_code == '201'
      used_ip_address =  @vm_new.ip_address
    end

    skip('The user has no suitable used IP') unless used_ip_address

    if @cp_version < 5.4
      vm.network_interface.allocate_new_ip(ip_address_id: @vm_new.network_interface.ip_address.id, used_ip: 1)
    else
      vm.network_interface.allocate_new_ip(used_ip: 1, address: used_ip_address)
    end

    @vm.rebuild_network

    if @cp_version >= 5.4
      expect(vm.ip_addresses.first.interface.conn.page.body.map {|ip_addr| ip_addr.ip_address_join.ip_address.address}.include?(used_ip_address)).to be true
      # expect(vm.ip_addresses.last.interface.conn.page.body.last.ip_address_join.ip_address.address).to eq(used_ip_address)
    end
    expect(vm.ip_addresses.count).to eq amount + 1
  end
end

shared_examples_for 'firewall' do
  it 'make sure route is unavailable' do
    vm.interface.get("#{vm.route}/firewall_rules")
    expect(vm.api_response_code).to eq '404'
    expect(@vma.conn.page.body.errors).to eq ["Resource Not Found"]
  end
end

shared_examples_for 'notes' do
  it 'should be created' do
    vm.add_note(admin_note: "ad-qa_ant_admin_note")
    expect(vm.admin_note).to eq "ad-qa_ant_admin_note"
  end

  it 'should be edited' do
    vm.add_note(admin_note: "ad-qa_ant_admin_note-edited")
    expect(vm.admin_note).to eq "ad-qa_ant_admin_note-edited"
  end

  it 'should be deleted' do
    vm.destroy_note("admin_note")
    expect(vm.admin_note).to be nil
  end

  it 'should be created' do
    vm.add_note(note: "ad-qa_ant_user_note")
    expect(vm.note).to eq "ad-qa_ant_user_note"
  end

  it 'should be edited' do
    vm.add_note(note: "ad-qa_ant_user_note")
    expect(vm.note).to eq "ad-qa_ant_user_note"
  end

  it 'should be deleted' do
    vm.destroy_note("note")
    expect(vm.note).to be nil
  end
end

shared_examples_for 'disk_actions' do
  def hot_actions_supported?
    @vma.hypervisor.distro != "centos5" && @vma.template.virtualization.include?('virtio') &&
        @vma.hypervisor.hypervisor_type == 'kvm'
  end

  it 'should not be added new(additional) disk' do
    expect(@vm.add_disk).to be nil
    expect(vm.api_response_code).to eq '422'
    expect(@vma.conn.page.body.errors.base).to eq ["New disk can not be added to EdgeServer"] if CdnServer::CDN_SERVER == 'edge_server'
    expect(@vma.conn.page.body.errors.base).to eq ["New disk can not be added to StorageServer"] if CdnServer::CDN_SERVER == 'storage_server'
    expect(@vma.conn.page.body.errors.base).to eq ["New disk can not be added to Accelerator"] if CdnServer::CDN_SERVER == 'accelerator'
  end

  it 'primary disk size should be increased on virtual server' do
    new_disk_size = vm.disk.disk_size + 2
    vm.disk.edit(disk_size: new_disk_size)
    expect(vm.pinged? && vm.exist_on_hv?).to be true
    vm.info_update
    expect(vm.disk.disk_size).to eq new_disk_size
  end

  it 'primary disk size should be decreased on virtual server' do
    new_disk_size = vm.disk.disk_size - 1
    vm.disk.edit(disk_size: new_disk_size)
    expect(vm.pinged? && vm.exist_on_hv?).to be true
    vm.info_update
    expect(vm.disk.disk_size).to eq new_disk_size
  end

  it 'should be impossible to add second primary disk with template min_disk_size to VS' do
    vm.add_disk(primary: true, primary_disk_size: vm.template.min_disk_size)
    expect(vm.api_response_code).to eq '422'
  end

  it 'should be impossible to add second primary disk with minimal available size to VS' do
    vm.add_disk(primary: true)
    expect(vm.api_response_code).to eq '422'
  end

  it 'should be possible increase size of swap disk' do
    skip "the swap disk is forbidden in UI"
    new_swap_disk_size=vm.disk('swap').disk_size + 2
    vm.disk('swap').edit(disk_size: new_swap_disk_size)
    expect(vm.pinged? && vm.exist_on_hv?).to be true
    vm.info_update
    expect(vm.disk('swap').disk_size).to eq new_swap_disk_size
  end

  it 'should be possible decrease size of swap disk' do
    skip "the swap disk is forbidden in UI"
    new_swap_disk_size=vm.disk('swap').disk_size - 1
    vm.disk('swap').edit(disk_size: new_swap_disk_size)
    expect(vm.pinged? && vm.exist_on_hv?).to be true
    vm.info_update
    expect(vm.disk('swap').disk_size).to eq new_swap_disk_size
  end

  it 'primary disk should be migrated if there is available DS on a cloud' do
    datastore_id = vm.disk.available_data_store_for_migration
    if datastore_id
      vm.disk.migrate(datastore_id)
      expect(vm.disk.data_store_id).to eq datastore_id
    else
      skip("skipped because we have not found available data stores for migration.")
    end
  end

  #TODO increase disk size during unlocking
end

shared_examples_for 'rerun_edge_srcipt' do
  it 'rerun cdn script' do
    unless vm.edge_status == 'Inactive' || vm.edge_status == 'Active'
      expect(vm.rerun_cdn_scripts).to eq true
    else
      Log.info("#{CdnServer::CDN_SERVER}(#{CdnServer::CDN_SERVER_TYPE}): edge_status = ACTIVE")
    end
  end
end

shared_examples_for 'edit' do
  it 'RAM' do
    new_ram = vm.memory.to_i + 10
    vm.edit(memory: new_ram)
    expect(vm.memory).to eq new_ram
  end

  it 'CPU' do
    new_cpus = vm.cpus + 1
    vm.edit_cpus(cpus: new_cpus)
    expect(vm.cpus).to eq new_cpus
  end

  it 'Label' do
    new_label = "#{vm.label}-edit"
    vm.edit(label: new_label)
    expect(vm.label).to eq new_label
  end

  it 'set vip' do
    skip "https://onappdev.atlassian.net/browse/CORE-8814"
    if vm.vip == (nil || false)
      vm.set_vip({vip: "true"})
      expect(vm.vip).to eq true
    else
      vm.set_vip({vip: "false"})
      expect(vm.vip).to eq false
    end
  end
end

shared_examples 'get_statistics' do
  it 'get cpu_usage' do
    vm.interface.get(vm.route_cpu_usage)
    expect(vm.api_response_code).to eq '200'
  end

  it 'get vm_stats' do
    vm.interface.get(vm.route_cpu_usage)
    expect(vm.api_response_code).to eq '200'
  end
end

shared_examples 'change_owners' do
  before do
    @new_user = User.new(@vma).create(first_name: 'Andrii-autotest', last_name:  Faker::Name.last_name)
    @owner = @vm.user_id
  end

  after do
    @vm.change_owner(@owner)
    @new_user.remove
  end

  it 'Change owner' do
    vm.change_owner(@new_user.id)
    expect(vm.user_id).to eq @new_user.id
  end
end

shared_examples 'negative' do
  it 'Reboot in recovery' do
    skip 'it is forbidden via UI, https://onappdev.atlassian.net/browse/CORE-8726'
    vm.reboot(recovery: true)
    expect(vm.port_opened?).to be true
    creds = {'es_host' => vm.ip_address, 'es_pass' => vm.initial_root_password}
    expect(vm.interface.execute_with_pass(creds, 'hostname')).to include 'recovery'
    vm.reboot
    expect(vm.pinged?).to be true
    expect(vm.port_opened?).to be true
  end

  it 'set_ssh_keys' do
    vm.set_ssh_keys
    expect(vm.api_response_code).to eq '404'
  end

  it 'reset_root_password' do
    vm.reset_root_password
    expect(vm.api_response_code).to eq '404'
  end

  it 'reboot_from_iso' do
    skip 'it is forbidden via UI, https://onappdev.atlassian.net/browse/CORE-9918'
    vm.reboot_from_iso
    expect(vm.api_response_code).to eq '404'
  end

  it 'recipe_joins' do
    vm.recipe_joins
    expect(vm.api_response_code).to eq '404'
    end

  it 'autoscale_enable' do
    vm.autoscale_enable
    expect(vm.api_response_code).to eq '404'
  end
end