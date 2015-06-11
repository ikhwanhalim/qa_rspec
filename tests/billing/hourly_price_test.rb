# Test for checking Hourly Price.

require './lib/onapp_billing'
require './lib/onapp_base_resource'
require './lib/virtual_machine/vm_base'
require './lib/virtual_machine/vm_stat'
require './lib/onapp_user'
require './lib/helpers/template_manager'
require './lib/helpers/hypervisor'
require './lib/onapp_settings/settings'
require './lib/backups/incremental'
require './lib/backups/normal'

include Hypervisor
include TemplateManager
include VmStat

def vm_resources_price_on_usage(vm, hv_br_data, ds_br_data, ntw_br_data)
  #price ON
  cpu_price = (vm.cpus - hv_br_data[:limits][:limit_free_cpu].to_i) * hv_br_data[:prices][:price_on_cpu].to_i
  cpu_shares_price = (vm.cpu_shares - hv_br_data[:limits][:limit_free_cpu_share].to_i) * hv_br_data[:prices][:price_on_cpu_share].to_i
  memory_price = (vm.memory - hv_br_data[:limits][:limit_free_memory].to_i) * hv_br_data[:prices][:price_on_memory].to_i
  total_disks_size = 0
  vm.disks.each do |disk|
    total_disks_size += disk['disk']['disk_size']
  end
  disks_price = (total_disks_size - ds_br_data[:limits][:limit_free].to_i) * ds_br_data[:prices][:price_on].to_i

  total_ips = vm.ip_addresses.length
  ip_price = (total_ips - ntw_br_data[:limits][:limit_ip_free].to_i) * ntw_br_data[:prices][:price_ip_on].to_i
  rate_limit_price = (vm.network_interfaces.first['network_interface']['rate_limit'] - ntw_br_data[:limits][:limit_rate_free].to_i) * ntw_br_data[:prices][:price_rate_on].to_i

  price_on = cpu_price + cpu_shares_price + memory_price + disks_price + ip_price + rate_limit_price
  return price_on

end

def vm_resources_price_off_usage(vm, hv_br_data, ds_br_data, ntw_br_data)
  #price OFF
  cpu_price = (vm.cpus - hv_br_data[:limits][:limit_free_cpu].to_i)  * hv_br_data[:prices][:price_off_cpu].to_i
  cpu_shares_price = (vm.cpu_shares - hv_br_data[:limits][:limit_free_cpu_share].to_i) * hv_br_data[:prices][:price_off_cpu_share].to_i
  memory_price = (vm.memory - hv_br_data[:limits][:limit_free_memory].to_i) * hv_br_data[:prices][:price_off_memory].to_i
  total_disks_size = 0
  vm.disks.each do |disk|
    total_disks_size += disk['disk']['disk_size']
  end
  disks_price = (total_disks_size - ds_br_data[:limits][:limit_free].to_i) * ds_br_data[:prices][:price_off].to_i

  total_ips = vm.ip_addresses.length
  ip_price = (total_ips - ntw_br_data[:limits][:limit_ip_free].to_i) * ntw_br_data[:prices][:price_ip_off].to_i
  rate_limit_price = (vm.network_interfaces.first['network_interface']['rate_limit'] - ntw_br_data[:limits][:limit_rate_free].to_i) * ntw_br_data[:prices][:price_rate_off].to_i

  price_off = cpu_price + cpu_shares_price + memory_price + disks_price + ip_price + rate_limit_price
  return price_off

end

describe "Checking Billing Plan functionality" do
  before(:all) do
    @bp = OnappBilling.new
    @hv_br = OnappBaseResource.new
    @ds_br = OnappBaseResource.new
    @ntw_br = OnappBaseResource.new
    @user = OnappUser.new

    #create BP
    bp_data = {:label => 'Test Hourly Price BP',
               :monthly_price => '100.0',
               :currency_code => 'USD'
    }
    @bp.create_billing_plan(bp_data)

    # Create User
    @user_data = {:login => 'hourlypricechecker',
                  :email => 'hourlypricechecker@user.test',
                  :password => 'hourlypricecheckerqwaszxsdomino!Q2',
                  :role_ids => [1],
                  :billing_plan_id => @bp.bp_id
    }
    response = @user.create_user(@user_data)
    expect(response['login']).to eq(@user_data[:login])

    @template = @user.get_template(ENV['TEMPLATE_MANAGER_ID'])
    @hypervisor = @user.for_vm_creation(ENV['VIRT_TYPE'])
    @hvz_id = @hypervisor['hypervisor_group_id']
    @dsz_id = @user.get_dsz_id(@hvz_id)
    @netz_id = @user.get_net_zone_id(@hvz_id)



    # Add base resources to BP
    # HV
    @hv_br_data = {:resource_class => "Resource::HypervisorGroup",
                   :target_id => @hvz_id,
                   :target_type => "Pack",
                   :limits => {:limit_free_cpu => "1",
                               :limit_cpu => "2",
                               :limit_free_cpu_share => "1",
                               :limit_cpu_share => "",
                               :limit_free_memory => @template['min_memory_size'],
                               :limit_memory => "1024"
                   },
                   :prices => {:price_on_cpu => "10",
                               :price_off_cpu => "2",
                               :price_on_cpu_share => "10",
                               :price_off_cpu_share => "2",
                               :price_on_memory => "10",
                               :price_off_memory => "2"
                   }
    }
    @hv_br.create_base_resource(@bp.bp_id, @hv_br_data)

    # DS
    @ds_br_data = {:resource_class => "Resource::DataStoreGroup",
                   :target_id => @dsz_id,
                   :target_type => "Pack",
                   :limits=> {:limit_free=>"6",
                              :limit => "20",
                              :limit_reads_completed_free => "1",
                              :limit_data_written_free => "1",
                              :limit_data_read_free => "1",
                              :limit_writes_completed_free => "1"
                   },
                   :limit_type => "hourly",
                   :prices => {:price_data_written => "10",
                               :price_off => "1",
                               :price_on => "10",
                               :price_data_read => "10",
                               :price_writes_completed => "10",
                               :price_reads_completed => "10"
                   }
    }
    @ds_br.create_base_resource(@bp.bp_id, @ds_br_data)

    # NW
    @ntw_br_data = {:resource_class => "Resource::NetworkGroup",
                    :target_id => @netz_id,
                    :target_type => "Pack",
                    :limits => {:limit_ip => "2",
                                :limit_rate => nil,
                                :limit_data_sent_free => "1",
                                :limit_rate_free => nil,
                                :limit_ip_free => "1",
                                :limit_data_received_free =>"1"
                    },
                    :limit_type => "hourly",
                    :prices => {:price_ip_off => "1",
                                :price_ip_on => "10",
                                :price_rate_off => "1",
                                :price_rate_on => "10",
                                :price_data_sent => "10",
                                :price_data_received => "10"
                    }
    }
    @ntw_br.create_base_resource(@bp.bp_id, @ntw_br_data)

    # Create VS
    @vm = VirtualMachine.new(@user)
    @vm.create(ENV['TEMPLATE_MANAGER_ID'],ENV['VIRT_TYPE'])
    @vm.wait_for_start
  end

  after(:all) do
    @vm.destroy
    @vm.wait_for_destroy
    data = {:force => true}
    @user.delete_user(data)
    @bp.delete_billing_plan()
  end

  it 'Check hourly price (On/Off) for free VS (Price should be 0.0)' do
    price_on = vm_resources_price_on_usage(@vm, @hv_br_data, @ds_br_data, @ntw_br_data)
    puts "Billing Price ON - #{price_on}"
    puts "VS Price ON - #{@vm.price_per_hour}"
    price_off = vm_resources_price_off_usage(@vm, @hv_br_data, @ds_br_data, @ntw_br_data)
    puts "Billing Price OFF - #{price_off}"
    puts "VS Price OFF - #{@vm.price_per_hour_powered_off}"
    expect(@vm.price_per_hour.to_i).to eq(price_on) and expect(@vm.price_per_hour_powered_off.to_i).to eq(price_off)

  end

  # Change BP
  it "Change BP to get Price for resources" do
  # HV
    @hv_br_data[:limits] = {:limit_free_cpu => "0",
                            :limit_cpu => "2",
                            :limit_free_cpu_share => "0",
                            :limit_cpu_share => "",
                            :limit_free_memory => "0",
                            :limit_memory => "1024"
    }
    @hv_br.edit_base_resource(@bp.bp_id, @hv_br.br_id, @hv_br_data)

    # DS
    @ds_br_data[:limits] = {:limit_free=>"0",
                            :limit => "20",
                            :limit_reads_completed_free => "0",
                            :limit_data_written_free => "0",
                            :limit_data_read_free => "0",
                            :limit_writes_completed_free => "0"
    }
    @ds_br.edit_base_resource(@bp.bp_id, @ds_br.br_id, @ds_br_data)

    # NW
    @ntw_br_data[:limits] = {:limit_ip => "2",
                             :limit_rate => "500",
                             :limit_data_sent_free => "0",
                             :limit_rate_free => "0",
                             :limit_ip_free => "0",
                             :limit_data_received_free =>"0"
    }
    @ntw_br.edit_base_resource(@bp.bp_id, @ntw_br.br_id, @ntw_br_data)
  end

  it 'Check hourly price (On/Off) for not free VS.' do
    @vm.info_update
    price_on = vm_resources_price_on_usage(@vm, @hv_br_data, @ds_br_data, @ntw_br_data)
    puts "Billing Price ON - #{price_on}"
    puts "VS Price ON - #{@vm.price_per_hour}"
    price_off = vm_resources_price_off_usage(@vm, @hv_br_data, @ds_br_data, @ntw_br_data)
    puts "Billing Price OFF - #{price_off}"
    puts "VS Price OFF - #{@vm.price_per_hour_powered_off}"
    expect(@vm.price_per_hour.to_i).to eq(price_on) and expect(@vm.price_per_hour_powered_off.to_i).to eq(price_off)

  end

  # Turn Off VS from UI, check hourly price and booted value - should be 0.
  it 'Check hourly price for shut downed VS.' do
    @vm.shut_down
    @vm.wait_for_stop
    @vm.info_update
    if !@vm.booted?
      # Get price_for_last_hour
      hprices = @vm.price_for_last_hour
      price_off = hprices[:vm_resources_cost]
      puts "Billing Price OFF - #{price_off}"
      puts "VS Price OFF - #{@vm.price_per_hour_powered_off}"
      expect(@vm.price_per_hour_powered_off.to_i).to eq(price_off)
    else
      puts "VS is booted!!!"
    end
  end

  # Turn On VS from UI, check hourly price and booted value - should be 1.
  it 'Check hourly price for booted VS.' do
    @vm.start_up
    @vm.wait_for_start
    @vm.info_update
    if @vm.booted?
      # Get price_for_last_hour
      hprices = @vm.price_for_last_hour
      price_on = hprices[:vm_resources_cost]
      puts "Billing Price ON - #{price_on}"
      puts "VS Price ON - #{@vm.price_per_hour}"
      expect(@vm.price_per_hour.to_i).to eq(price_on)
    else
      puts "VS not booted!!!"
    end
  end

  # Shutdown VS from inside, check hourly price and booted value - should be 0.
  it 'Check hourly price for shut downed VS from inside.' do
    attempts = 5
    @vm.execute_with_pass("init 0")
    while attempts != 0 do
      @vm.info_update
      if !@vm.booted?
        break
      end
      attempts -= 1
      sleep(5)
    end
    # Get price_for_last_hour
    hprices = @vm.price_for_last_hour
    price_off = hprices[:vm_resources_cost]
    puts "Billing Price OFF - #{price_off}"
    puts "VS Price OFF - #{@vm.price_per_hour_powered_off}"
    expect(@vm.price_per_hour_powered_off.to_i).to eq(price_off)
  end


  # TODO
  # Edit base resources
  # Download file
  it "Download 1GB file." do
    @vm.info_update
    if !@vm.booted?
      @vm.start_up
      @vm.wait_for_start
      @vm.ssh_port_opened
    end
    @vm.execute_with_pass("wget http://mirror.internode.on.net/pub/test/1000meg.test")
    # TODO
    # Check if file present on VS with appropriate size

  end
  # Create File
  it "Write 1GB file on disk." do
    @vm.info_update
    if !@vm.booted?
      @vm.start_up
      @vm.wait_for_start
      @vm.ssh_port_opened
    end
    @vm.execute_with_pass("cp ./1000meg.test ./one_more1000meg.test")
    # TODO
    # Check if file present on VS with appropriate size
  end
  # Create Backup
  # Convert to template
  # Check prices
  #hprices = @vm.price_for_last_hour

  it "Check settings" do
    settings = Settings.new
    cfg = settings.get_config
    if !cfg['allow_incremental_backups']
      cfg['allow_incremental_backups'] = true
      Log.info("Settings will be changed to 'allow_incremental_backups' - true.")
      settings.edit_config(data=cfg)
      Log.info("Settings has been successfully saved.")
    end
    Log.info("'allow_incremental_backups' already true.")
  end

  it "Check incremental backups functionality." do
    ib = Incremental.new
    ib.create(@vm.identifier)
    ib.restore(backup_id=ib.id, type=ib.type)
    ib.convert_to_template(backup_id=ib.id, data={:label => "Autotest - #{Time.now}"})
    ib.delete(backup_id=ib.id)
  end

end
