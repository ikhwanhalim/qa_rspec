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
require './lib/helpers/onapp_http'

include Hypervisor
include TemplateManager
include VmStat
include OnappHTTP

def vm_port_speed(vm)
  vm_rate_limit = vm.network_interfaces.first['network_interface']['rate_limit']
  vm_network_interface_port_speed = vm_rate_limit == 0 ? @onapp_yml.cfg['ip_range_limit'].to_i : vm_rate_limit
  return vm_network_interface_port_speed
end

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
  # Checking for unlimited value #######################################################################################
  br_rate_limit = ntw_br_data[:limits][:limit_rate_free]
  free_rate_limit = br_rate_limit == '' ? @onapp_yml.cfg['ip_range_limit'].to_i : br_rate_limit.to_i
  ######################################################################################################################
  rate_limit_price = (vm_port_speed(vm) - free_rate_limit) * ntw_br_data[:prices][:price_rate_on].to_i
  puts "Rate limit price - #{rate_limit_price}"

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
  # Checking for unlimited value #######################################################################################
  br_rate_limit = ntw_br_data[:limits][:limit_rate_free]
  free_rate_limit = br_rate_limit == '' ? @onapp_yml.cfg['ip_range_limit'].to_i : br_rate_limit.to_i
  ######################################################################################################################
  rate_limit_price = (vm_port_speed(vm) - free_rate_limit) * ntw_br_data[:prices][:price_rate_off].to_i

  price_off = cpu_price + cpu_shares_price + memory_price + disks_price + ip_price + rate_limit_price
  return price_off

end

describe "Checking Billing Plan functionality" do
  before(:all) do
    @bp = OnappBilling.new
    @template_br = OnappBaseResource.new
    @storage_disk_size_br = OnappBaseResource.new
    @backup_br = OnappBaseResource.new
    @hv_br = OnappBaseResource.new
    @ds_br = OnappBaseResource.new
    @ntw_br = OnappBaseResource.new
    @bs_br = OnappBaseResource.new
    @user = OnappUser.new
    @onapp_yml = Settings.new
    @onapp_yml.get_config

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
    @user_stat = @user.get_user_stat

    @template = @user.get_template(ENV['TEMPLATE_MANAGER_ID'])
    @hypervisor = @user.for_vm_creation(ENV['VIRT_TYPE'])
    @hvz_id = @hypervisor['hypervisor_group_id']
    @dsz_id = @user.get_dsz_id(@hvz_id)
    @netz_id = @user.get_net_zone_id(@hvz_id)
    @bsz_id = @bs_br.get_zone_id(type=:backup)

    # Add base resources to BP
    # Add Limits for User VSs
    # Template
    @template_br_data = {:resource_class => "Resource::Template",
                         :limits => {:limit => "1",
                                     :limit_free => "0"
                         },
                         :prices => {:price => "10"
                         }
    }
    @template_br.create_base_resource(@bp.bp_id, @template_br_data)
    # Storage Disk Size
    @storage_disk_size_br_data = {:resource_class => "Resource::StorageDiskSize",
                         :limits => {:limit => "1",
                                     :limit_free => "0"
                         },
                         :prices => {:price => "10"
                         }
    }
    @storage_disk_size_br.create_base_resource(@bp.bp_id, @storage_disk_size_br_data)
    # Backup
    @backup_br_data = {:resource_class => "Resource::Backup",
                         :limits => {:limit => "1",
                                     :limit_free => "0"
                         },
                         :prices => {:price => "10"
                         }
    }
    @backup_br.create_base_resource(@bp.bp_id, @backup_br_data)
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
                                :limit_rate => "",
                                :limit_data_sent_free => "1",
                                :limit_rate_free => "",
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

    # BS
    @bsz_br_data = {:resource_class => "Resource::BackupServerGroup",
                    :target_id => @bsz_id,
                    :target_type => "Pack",
                    :limits => {:limit_backup_free => '0',
                                :limit_backup => '1',
                                :limit_backup_disk_size_free => '0',
                                :limit_backup_disk_size => nil,
                                :limit_template_disk_size_free => '0',
                                :limit_template_disk_size => nil,
                                :limit_template_free => '0',
                                :limit_template => '1'
                    },
                    :prices => {:price_backup => '10',
                                :price_backup_disk_size => '100',
                                :price_template => '10',
                                :price_template_disk_size => '100'
                    }
    }
    @bs_br.create_base_resource(@bp.bp_id, @bsz_br_data)
    # Create connection for backups
    @backup = Incremental.new(@user)
    #@template_from_backup = {}
    # Create VS
    @vm = VirtualMachine.new(@user)
    @vm.create(ENV['TEMPLATE_MANAGER_ID'],ENV['VIRT_TYPE'])
    @vm.wait_for_start
  end

  after(:all) do
    # 'Login' under admin
    @vm.destroy
    @vm.wait_for_destroy
    data = {:force => true}
    @user.delete_user(data)
    @bp.delete_billing_plan()
  end
#=begin
  it 'Check hourly price (On/Off) for free VS (Price should be 0.0)' do
    price_on = vm_resources_price_on_usage(@vm, @hv_br_data, @ds_br_data, @ntw_br_data)
    puts "Billing Price ON - #{price_on}"
    puts "VS Price ON - #{@vm.price_per_hour}"
    price_off = vm_resources_price_off_usage(@vm, @hv_br_data, @ds_br_data, @ntw_br_data)
    puts "Billing Price OFF - #{price_off}"
    puts "VS Price OFF - #{@vm.price_per_hour_powered_off}"
    expect(@vm.price_per_hour.to_i).to eq(price_on) and expect(@vm.price_per_hour_powered_off.to_i).to eq(price_off)

  end
#=end
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
                             :limit_rate => nil,
                             :limit_data_sent_free => "0",
                             :limit_rate_free => "0",
                             :limit_ip_free => "0",
                             :limit_data_received_free =>"0"
    }
    @ntw_br.edit_base_resource(@bp.bp_id, @ntw_br.br_id, @ntw_br_data)
    puts "BSZ ID - #{@bsz_id}"
  end
#=begin
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
  it "'Write' 1GB file on disk." do
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
#=end
  # Create Backup
  it "Create Backup to check price" do
    if !@onapp_yml.cfg['allow_incremental_backups']
      @onapp_yml.cfg['allow_incremental_backups'] = true
      Log.info("Settings will be changed to 'allow_incremental_backups' - true.")
      settings.edit_config(data=@onapp_yml.cfg)
      Log.info("Settings has been successfully saved.")
    end
    Log.info("'allow_incremental_backups' already true.")
    @backup.create(@vm.identifier)
  end
  # Convert to template
  it "Convert to template. (To check price)" do
    @backup.convert_to_template(backup_id=@backup.id, data={:label => "Autotest - #{Time.now}"})
  end

  # Check Usage Statistics
  it "Get Usage Statistics" do
    vm_stats_waiter
    @user.get_user_stat
    puts @user.user_stats
    @user.user_stats.each do |key, value|
      puts "#{key} - #{value}"
    end
  end

  it "Check template cost" do
    if !@backup.template_on_bs?
      expect(@user.user_stats['template_cost']).to eq(@template_br_data[:prices][:price].to_f)
    else
      expect(@user.user_stats['template_cost']).to eq(0.0)
    end
  end

  it "Check template count cost" do
    if @backup.template_on_bs?
      expect(@user.user_stats['template_count_cost']).to eq(@bsz_br_data[:prices][:price_template].to_f)
    else
      expect(@user.user_stats['template_count_cost']).to eq(0.0)
    end
  end

  it "Check template disk size cost" do
    if @backup.template_on_bs?
      expect(@user.user_stats['template_disk_size_cost'].round(2)).to eq(((@backup.size(backup_id=@backup.id) / 1024.0 / 1024.0) * @bsz_br_data[:prices][:price_template_disk_size].to_i).round(2))
    else
      expect(@user.user_stats['template_disk_size_cost'].round(2)).to eq(0.0)
    end
  end

  it "Check backup cost" do
    if !@backup.on_backup_server?(backup_id=@backup.id)
      expect(@user.user_stats['backup_cost']).to eq(@backup_br_data[:prices][:price].to_f)
    else
      expect(@user.user_stats['backup_cost']).to eq(0.0)
    end
  end

  it "Check backup count cost" do
    if @backup.on_backup_server?(backup_id=@backup.id)
      expect(@user.user_stats['backup_count_cost']).to eq(@bsz_br_data[:prices][:price_backup].to_f)
    else
      expect(@user.user_stats['backup_count_cost']).to eq(0.0)
    end
  end

  it "Check backup disk size cost" do
    if @backup.on_backup_server?(backup_id=@backup.id)
      expect(@user.user_stats['backup_disk_size_cost'].round(2)).to eq(((@backup.size(backup_id=@backup.id) / 1024.0 / 1024.0) * @bsz_br_data[:prices][:price_backup_disk_size].to_i).round(2))
    else
      expect(@user.user_stats['backup_disk_size_cost'].round(2)).to eq(0.0)
    end
  end

  it "Check Storage Disk Size cost" do
    # if template/backup is located on HV
    total_size = 0
    template_on_bs = true ? @backup.template_from_backup['backup_server_id'].class == Fixnum : false
    if !@backup.on_backup_server?(backup_id=@backup.id)
      total_size += @backup.size(backup_id=@backup.id)
    elsif !template_on_bs
      total_size += @backup.template_from_backup['template_size']
    else
      puts "Storage Disk Size cost - 0.0"
    end
    expect(@user.user_stats['storage_disk_size_cost'].round(2)).to eq((total_size * @storage_disk_size_br_data[:prices][:price].to_f).round(2))
  end

  # Check Usage Statistics
  it "Check Usage Statistics" do
    # TODO extend tests
    @vm.vs_hstats
  end

  it "Check Disk size cost" do
    total_disk_size = 0
    @vm.disks.each do |disk|
      total_disk_size += disk['disk']['disk_size']
    end
    expect(@vm.vs_hstats[:disks_size_cost]).to eq(@ds_br_data[:prices][:price_on].to_f * total_disk_size)
  end

  it "Check Data Read cost" do
    expected_price = @ds_br_data[:prices][:price_data_read].to_f * 1
    expect(@vm.vs_hstats[:data_read_cost]).to be_within(expected_price/10.0).of(expected_price)
  end

  it "Check Data Written cost" do
    expected_price = @ds_br_data[:prices][:price_data_written].to_f * 2
    expect(@vm.vs_hstats[:data_written_cost]).to be_within(expected_price/10.0).of(expected_price)
  end

  #it "Check Reads Completed cost" do

  #end

  #it "Check Writes Completed cost" do

  #end

  it "Check IP Address cost" do
    expect(@vm.vs_hstats[:ip_address_cost]).to eq(@vm.ip_addresses.length * @ntw_br_data[:prices][:price_ip_on].to_f)
  end

  it "Check Rate cost" do
    expect(@vm.vs_hstats[:rate_cost]).to eq(vm_port_speed(@vm) * @ntw_br_data[:prices][:price_rate_on].to_f)
  end

  it "Check Data Received cost" do
    expected_price = @ntw_br_data[:prices][:price_data_received].to_f * 1
    expect(@vm.vs_hstats[:data_received_cost]).to be_within(expected_price/10.0).of(expected_price)
  end

  it "Check Data Sent cost" do
    expected_price = @ntw_br_data[:prices][:price_data_sent].to_f * 0.2
    expect(@vm.vs_hstats[:data_sent_cost]).to be_within(expected_price/1.0).of(expected_price)
  end

  it "Check CPU Shares cost" do
    expect(@vm.vs_hstats[:cpu_shares_cost]).to eq(@vm.cpu_shares * @hv_br_data[:prices][:price_on_cpu_share].to_f )
  end

  it "Check CPUs cost" do
    expect(@vm.vs_hstats[:cpus_cost]).to eq(@vm.cpus * @hv_br_data[:prices][:price_on_cpu].to_f )
  end

  it "Check Memory cost" do
    expect(@vm.vs_hstats[:memory_cost]).to eq(@vm.memory * @hv_br_data[:prices][:price_on_memory].to_f )
  end

  #it "Check Template cost" do

  #end

  #it "Check CPU Usage cost" do

  #end

  #it "Check Total cost" do

  #end

  #it "Check VM Resources cost" do

  #end

  #it "Check Usage cost" do

  #end




#=begin
  # Turn Off VS from UI, check hourly price and booted value - should be 0.
  it 'Check hourly price for shut downed VS.' do
    @vm.shut_down
    @vm.wait_for_stop
    @vm.info_update
    if !@vm.booted?
      # Get price_for_last_hour
      @vm.vm_stats_waiter
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
      @vm.vm_stats_waiter
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
    @vm.vm_stats_waiter
    hprices = @vm.price_for_last_hour
    price_off = hprices[:vm_resources_cost]
    puts "Billing Price OFF - #{price_off}"
    puts "VS Price OFF - #{@vm.price_per_hour_powered_off}"
    expect(@vm.price_per_hour_powered_off.to_i).to eq(price_off)
  end

  # Check prices
  #hprices = @vm.price_for_last_hour
#=end
  # Check prices for user_statistics on /users/:id/user_statistics page
  # Create payment, check that "Billing Details" has changed.
end
