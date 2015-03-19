# Test for checking Hourly Price.

require './lib/onapp_billing'
require './lib/onapp_base_resource'
require './lib/virtual_machine/vm_base'
require './lib/virtual_machine/vm_stat'
require './lib/onapp_user'
require './lib/helpers/template_manager'
require './lib/helpers/hypervisor'

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
                                :limit_rate => "500",
                                :limit_data_sent_free => "1",
                                :limit_rate_free => "1",
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

  it 'Check hourly price' do
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

  it 'Check ON/OFF prices' do
    @vm.info_update
    price_on = vm_resources_price_on_usage(@vm, @hv_br_data, @ds_br_data, @ntw_br_data)
    puts "Billing Price ON - #{price_on}"
    puts "VS Price ON - #{@vm.price_per_hour}"
    price_off = vm_resources_price_off_usage(@vm, @hv_br_data, @ds_br_data, @ntw_br_data)
    puts "Billing Price OFF - #{price_off}"
    puts "VS Price OFF - #{@vm.price_per_hour_powered_off}"
    expect(@vm.price_per_hour.to_i).to eq(price_on) and expect(@vm.price_per_hour_powered_off.to_i).to eq(price_off)

  end

  # TODO
  it 'Check price when VS is shutdown.' do
    # Shutdown VS from UI, check hourly price and built value - should be 0.
    @vm.shut_down
    @vm.wait_for_stop
    # Get price_for_last_hour
    price_off = @vm.price_for_last_hour
    puts "Billing Price OFF - #{price_off}"
    puts "VS Price OFF - #{@vm.price_per_hour_powered_off}"
    expect(@vm.price_per_hour_powered_off.to_i).to eq(price_off)
  end

  # Turn On VS from UI, check hourly price and built value - should be 1.
  it 'Check price when VS is startup.' do
    # Shutdown VS from UI, check hourly price and built value - should be 0.
    @vm.start_up
    @vm.wait_for_start
    # Get price_for_last_hour
    price_on = @vm.price_for_last_hour
    puts "Billing Price ON - #{price_on}"
    puts "VS Price ON - #{@vm.price_per_hour}"
    expect(@vm.price_per_hour.to_i).to eq(price_on)
  end

  # Shutdown VS from inside, check hourly price and built value - should be 0.
  it 'Check price when VS is startup.' do
    # Shutdown VS from UI, check hourly price and built value - should be 0.
    @vm.execute_with_pass("init 0")
    #@vm.start_up
    #@vm.wait_for_start
    # Get price_for_last_hour
    price_off = @vm.price_for_last_hour
    puts "Billing Price OFF - #{price_off}"
    puts "VS Price OFF - #{@vm.price_per_hour_powered_off}"
    expect(@vm.price_per_hour_powered_off.to_i).to eq(price_off)
  end
end
