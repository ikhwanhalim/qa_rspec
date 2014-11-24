# Test for checking Hourly Price.

require './lib/onapp_billing'
require './lib/onapp_base_resource'
require './lib/virtual_machine/onapp_vm'
require './lib/onapp_user'
require './lib/onapp_template'
require './lib/helpers/hypervisor'

include Hypervisor

describe "Checking Billing Plan functionality" do
  before(:all) do
    @bp = OnappBilling.new
    @br = OnappBaseResource.new
    @user = OnappUser.new

    @template = OnappTemplate.new("ubuntu-14.04-x64-1.0-xen.kvm.kvm_virtio.tar.gz")
    virtualization = @template.virtualization.split(',')
    zones_ids = @br.hdn_zones_ids(virtualization)
    @hvz_id = zones_ids[:hvz_id]
    puts @hvz_id
    @dsz_id = zones_ids[:dsz_id]
    @netz_id = zones_ids[:netz_id]

    #create BP
    bp_data = {:label => 'Test Hourly Price BP',
               :monthly_price => '100.0',
               :currency_code => 'USD'
    }
    @bp.create_billing_plan(bp_data)

    # Add base resources to BP
    # HV
    @hv_br_data = {:resource_class => "Resource::HypervisorGroup",
                   :target_id => @hvz_id,
                   :target_type => "Pack",
                   :limits => {:limit_free_cpu => "1",
                               :limit_cpu => "2",
                               :limit_free_cpu_share => "1",
                               :limit_cpu_share => "",
                               :limit_free_memory => @template.min_memory_size,
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
    @br.create_base_resource(@bp.bp_id, @hv_br_data)

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
    @br.create_base_resource(@bp.bp_id, @ds_br_data)

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
    @br.create_base_resource(@bp.bp_id, @ntw_br_data)

    # Create User
    @user_data = {:login => 'hourlypricechecker',
                  :email => 'hourlypricechecker@user.test',
                  :password => 'hourlypricecheckerqwaszxsdomino!Q2',
                  :role_ids => [1],
                  :billing_plan_id => @bp.bp_id
    }
    response = @user.create_user(@user_data)
    expect(response['user']['login']).to eq(@user_data[:login])

    # Create VS
    @vm = VirtualMachine.new(@template.file_name, 'kvm6', @user)

  end

  after(:all) do
    @vm.destroy
    data = {:force => true}
    @user.delete_user(@user.user_id, data)
    @bp.delete_billing_plan(@bp.bp_id)
  end

  it 'Check hourly price' do
    expect(@vm.price_per_hour).to eq(0.0) and expect(@vm.price_per_hour_powered_off).to eq(0.0)

  end

end