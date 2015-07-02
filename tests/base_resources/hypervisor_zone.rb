# Check Hypervisor Zone limits
require './lib/onapp_base_resource'

describe "Check Hypervisor Zone limits" do
########################################################################################################################
  before(:all) do
    # Get real BackupServerZone id
    @bp = OnappBilling.new
    @br = OnappBaseResource.new
    # Create BP before testing
    @bp.create_billing_plan({:label => 'TestBPForBaseResources'})
    @bp_id = @bp.bp_id
    @hvz_id = @br.get_zone_id(type = :hypervisor)
  end

  after(:all) do
    @bp.delete_billing_plan()
  end
########################################################################################################################
  it "Create Hypervisor Zone limit with unexisted Hypervisor Zone id" do
    data = {:resource_class => "Billing::Resource::HypervisorGroup",
            :target_id => 0,
            :target_type => "Pack"
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['base'].first).to eq("Target not found")
  end
########################################################################################################################
  # Check 'CPU Cores' limits
########################################################################################################################
  # Check 'Free' limits
  it "Create 'CPU Cores' limit with negative 'Free' value" do
    data = {:resource_class => "Billing::Resource::HypervisorGroup",
            :target_id => @hvz_id,
            :target_type => "Pack",
            :limits => {
                :limit_free_cpu => -2
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['limit_free_cpu'].first).to eq("must be greater than or equal to 0")
  end

  it "Create 'CPU Cores' limit with pozitive 'Free' value > 0" do
    data = {:resource_class => "Billing::Resource::HypervisorGroup",
            :target_id => @hvz_id,
            :target_type => "Pack",
            :limits => {
                :limit_free_cpu => 2
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['limits']['limit_free_cpu']).to eq(data[:limits][:limit_free_cpu])
  end

  it "Edit 'CPU Cores' limit 'Free' value, set 0" do
    data = {:limits => {
                :limit_free_cpu => 0
            }
    }
    @br.edit_base_resource(@bp_id, @br.br_id, data)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response['limits']['limit_free_cpu']).to eq(data[:limits][:limit_free_cpu])
  end

  it "Delete 'CPU Cores' limit resource" do
    @br.delete_base_resource(@bp_id, @br.br_id)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response.first).to eq('Resource not found')
  end
########################################################################################################################
  # Check 'Max' limits
  it "Create 'CPU Cores' limit with negative 'Max' value" do
    data = {:resource_class => "Billing::Resource::HypervisorGroup",
            :target_id => @hvz_id,
            :target_type => "Pack",
            :limits => {
                :limit_cpu => -2
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['limit_cpu'].first).to eq("must be greater than or equal to 0")
  end

  it "Create 'CPU Cores' limit with pozitive 'Max' value > 0" do
    data = {:resource_class => "Billing::Resource::HypervisorGroup",
            :target_id => @hvz_id,
            :target_type => "Pack",
            :limits => {
                :limit_cpu => 2
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['limits']['limit_cpu']).to eq(data[:limits][:limit_cpu])
  end

  it "Edit 'CPU Cores' limit 'Max' value, set 0 (Unlimited)" do
    data = {:limits => {
                :limit_cpu => 0
            }
    }
    @br.edit_base_resource(@bp_id, @br.br_id, data)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response['limits']['limit_cpu']).to eq(data[:limits][:limit_cpu])
  end

  it "Delete 'CPU Cores' limit resource" do
    @br.delete_base_resource(@bp_id, @br.br_id)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response.first).to eq('Resource not found')
  end
########################################################################################################################
  # Check 'Prices On'
  it "Create 'CPU Cores' limit with negative 'Price On' value" do
    data = {:resource_class => "Billing::Resource::HypervisorGroup",
            :target_id => @hvz_id,
            :target_type => "Pack",
            :prices => {
                :price_on_cpu => -2
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['price_on_cpu'].first).to eq("must be greater than or equal to 0")
  end

  it "Create 'CPU Cores' limit with pozitive 'Price On' value > 0" do
    data = {:resource_class => "Billing::Resource::HypervisorGroup",
            :target_id => @hvz_id,
            :target_type => "Pack",
            :prices => {
                :price_on_cpu => 2
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['prices']['price_on_cpu']).to eq(data[:prices][:price_on_cpu].to_f)
  end

  it "Edit 'CPU Cores' limit 'Price On' value, set 0" do
    data = {:prices => {
        :price_on_cpu => 0
    }
    }
    @br.edit_base_resource(@bp_id, @br.br_id, data)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response['prices']['price_on_cpu']).to eq(data[:prices][:price_on_cpu])
  end

  it "Delete 'CPU Cores' limit resource" do
    @br.delete_base_resource(@bp_id, @br.br_id)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response.first).to eq('Resource not found')
  end
########################################################################################################################
  # Check 'Prices Off'
  it "Create 'CPU Cores' limit with negative 'Price Off' value" do 
    data = {:resource_class => "Billing::Resource::HypervisorGroup",
            :target_id => @hvz_id,
            :target_type => "Pack",
            :prices => {
                :price_off_cpu => -2
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['price_off_cpu'].first).to eq("must be greater than or equal to 0")
  end

  it "Create 'CPU Cores' limit with pozitive 'Price Off' value > 0" do 
    data = {:resource_class => "Billing::Resource::HypervisorGroup",
            :target_id => @hvz_id,
            :target_type => "Pack",
            :prices => {
                :price_off_cpu => 2
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['prices']['price_off_cpu']).to eq(data[:prices][:price_off_cpu].to_f)
  end

  it "Edit 'CPU Cores' limit 'Price Off' value, set 0" do
    data = {:prices => {
        :price_off_cpu => 0
    }
    }
    @br.edit_base_resource(@bp_id, @br.br_id, data)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response['prices']['price_off_cpu']).to eq(data[:prices][:price_off_cpu])
  end

  it "Delete 'CPU Cores' limit resource" do
    @br.delete_base_resource(@bp_id, @br.br_id)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response.first).to eq('Resource not found')
  end
########################################################################################################################
  # Check 'CPU Shares' limits
########################################################################################################################
  # Check 'Free' limits
  it "Create CPU Shares' limit with negative 'Free' value" do
    data = {:resource_class => "Billing::Resource::HypervisorGroup",
            :target_id => @hvz_id,
            :target_type => "Pack",
            :limits => {
                :limit_free_cpu_share => -2
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['limit_free_cpu_share'].first).to eq("must be greater than or equal to 0")
  end

  it "Create 'CPU Shares' limit with pozitive 'Free' value > 0" do 
    data = {:resource_class => "Billing::Resource::HypervisorGroup",
            :target_id => @hvz_id,
            :target_type => "Pack",
            :limits => {
                :limit_free_cpu_share => 2
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['limits']['limit_free_cpu_share']).to eq(data[:limits][:limit_free_cpu_share].to_f)
  end

  it "Edit 'CPU Shares' limit 'Free' value, set 0" do
    data = {:limits => {
                :limit_free_cpu_share => 0
            }
    }
    @br.edit_base_resource(@bp_id, @br.br_id, data)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response['limits']['limit_free_cpu_share']).to eq(data[:limits][:limit_free_cpu_share])
  end

  it "Delete 'CPU Shares' limit resource" do
    @br.delete_base_resource(@bp_id, @br.br_id)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response.first).to eq('Resource not found')
  end
########################################################################################################################
  # Check 'Max' limits
  it "Create 'CPU Shares' limit with negative 'Max' value" do
    data = {:resource_class => "Billing::Resource::HypervisorGroup",
            :target_id => @hvz_id,
            :target_type => "Pack",
            :limits => {
                :limit_cpu_share => -2
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['limit_cpu_share'].first).to eq("must be greater than or equal to 0")
  end

  it "Create 'CPU Shares' limit with pozitive 'Max' value > 0" do 
    data = {:resource_class => "Billing::Resource::HypervisorGroup",
            :target_id => @hvz_id,
            :target_type => "Pack",
            :limits => {
                :limit_cpu_share => 2
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['limits']['limit_cpu_share']).to eq(data[:limits][:limit_cpu_share].to_f)
  end

  it "Edit 'CPU Shares' limit 'Max' value, set 0 (Unlimited)" do
    data = {:limits => {
                :limit_cpu_share => 0
            }
    }
    @br.edit_base_resource(@bp_id, @br.br_id, data)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response['limits']['limit_cpu_share']).to eq(data[:limits][:limit_cpu_share])
  end

  it "Delete 'CPU Shares' limit resource" do
    @br.delete_base_resource(@bp_id, @br.br_id)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response.first).to eq('Resource not found')
  end
########################################################################################################################
  # Check 'Prices On'
  it "Create 'CPU Shares' limit with negative 'Price On' value" do 
    data = {:resource_class => "Billing::Resource::HypervisorGroup",
            :target_id => @hvz_id,
            :target_type => "Pack",
            :prices => {
                :price_on_cpu_share => -2
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['price_on_cpu_share'].first).to eq("must be greater than or equal to 0")
  end

  it "Create 'CPU Shares' limit with pozitive 'Price On' value > 0" do 
    data = {:resource_class => "Billing::Resource::HypervisorGroup",
            :target_id => @hvz_id,
            :target_type => "Pack",
            :prices => {
                :price_on_cpu_share => 2
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['prices']['price_on_cpu_share']).to eq(data[:prices][:price_on_cpu_share].to_f)
  end

  it "Edit 'CPU Shares' limit 'Price On' value, set 0" do
    data = {:prices => {
        :price_on_cpu_share => 0
    }
    }
    @br.edit_base_resource(@bp_id, @br.br_id, data)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response['prices']['price_on_cpu_share']).to eq(data[:prices][:price_on_cpu_share])
  end

  it "Delete 'CPU Shares' limit resource" do
    @br.delete_base_resource(@bp_id, @br.br_id)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response.first).to eq('Resource not found')
  end
########################################################################################################################
  # Check 'Prices Off'
  it "Create 'CPU Shares' limit with negative 'Price Off' value" do 
    data = {:resource_class => "Billing::Resource::HypervisorGroup",
            :target_id => @hvz_id,
            :target_type => "Pack",
            :prices => {
                :price_off_cpu_share => -2
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['price_off_cpu_share'].first).to eq("must be greater than or equal to 0")
  end

  it "Create 'CPU Shares' limit with pozitive 'Price Off' value > 0" do 
    data = {:resource_class => "Billing::Resource::HypervisorGroup",
            :target_id => @hvz_id,
            :target_type => "Pack",
            :prices => {
                :price_off_cpu_share => 2
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['prices']['price_off_cpu_share']).to eq(data[:prices][:price_off_cpu_share].to_f)
  end

  it "Edit 'CPU Shares' limit 'Price Off' value, set 0" do
    data = {:prices => {
        :price_off_cpu_share => 0
    }
    }
    @br.edit_base_resource(@bp_id, @br.br_id, data)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response['prices']['price_off_cpu_share']).to eq(data[:prices][:price_off_cpu_share])
  end

########################################################################################################################
  it "Check 'Use CPU units?' switcher." do
    data = {:preferences => {
        :use_cpu_units => true
    }
    }
    @br.edit_base_resource(@bp_id, @br.br_id, data)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response['preferences']['use_cpu_units']).to eq(data[:preferences][:use_cpu_units])
  end

  it "Edit 'CPU Units' limit 'Free' value, set 0" do
    data = {:limits => {
                :limit_free_cpu_units => 0
            }
    }
    @br.edit_base_resource(@bp_id, @br.br_id, data)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response['limits']['limit_free_cpu_units']).to eq(data[:limits][:limit_free_cpu_units])
  end

  it "Edit 'CPU Units' limit 'Max' value, set 0 (Unlimited)" do
    data = {:limits => {
                :limit_cpu_units => 0
            }
    }
    @br.edit_base_resource(@bp_id, @br.br_id, data)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response['limits']['limit_cpu_units']).to eq(data[:limits][:limit_cpu_units])
  end

  it "Edit 'CPU Units' limit 'Price On' value, set 0" do
    data = {:prices => {
                :price_on_cpu_units => 0.0
            }
    }
    @br.edit_base_resource(@bp_id, @br.br_id, data)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response['prices']['price_on_cpu_units']).to eq(data[:prices][:price_on_cpu_units])
  end

  it "Edit 'CPU Units' limit 'Price Off' value, set 0" do
    data = {:prices => {
                :price_on_cpu_units => 0.0
            }
    }
    @br.edit_base_resource(@bp_id, @br.br_id, data)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response['prices']['price_on_cpu_units']).to eq(data[:prices][:price_on_cpu_units])
  end
########################################################################################################################
  it "Delete 'CPU Shares/Units' limit resource" do
    @br.delete_base_resource(@bp_id, @br.br_id)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response.first).to eq('Resource not found')
  end
########################################################################################################################
  # Check 'RAM' limits
########################################################################################################################
  # Check 'Free' limits
  it "Create 'RAM' limit with negative 'Free' value" do
    data = {:resource_class => "Billing::Resource::HypervisorGroup",
            :target_id => @hvz_id,
            :target_type => "Pack",
            :limits => {
                :limit_free_memory => -2
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['limit_free_memory'].first).to eq("must be greater than or equal to 0")
  end

  it "Create 'RAM' limit with pozitive 'Free' value > 0" do 
    data = {:resource_class => "Billing::Resource::HypervisorGroup",
            :target_id => @hvz_id,
            :target_type => "Pack",
            :limits => {
                :limit_free_memory => 2
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['limits']['limit_free_memory']).to eq(data[:limits][:limit_free_memory])
  end

  it "Edit 'RAM' limit 'Free' value, set 0" do
    data = {:limits => {
                :limit_free_memory => 0
            }
    }
    @br.edit_base_resource(@bp_id, @br.br_id, data)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response['limits']['limit_free_memory']).to eq(data[:limits][:limit_free_memory])
  end

  it "Delete 'RAM' limit resource" do
    @br.delete_base_resource(@bp_id, @br.br_id)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response.first).to eq('Resource not found')
  end
########################################################################################################################
  # Check 'Max' limits
  it "Create 'RAM' limit with negative 'Max' value" do
    data = {:resource_class => "Billing::Resource::HypervisorGroup",
            :target_id => @hvz_id,
            :target_type => "Pack",
            :limits => {
                :limit_memory => -2
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['limit_memory'].first).to eq("must be greater than or equal to 0")
  end

  it "Create 'RAM' limit with pozitive 'Max' value > 0" do 
    data = {:resource_class => "Billing::Resource::HypervisorGroup",
            :target_id => @hvz_id,
            :target_type => "Pack",
            :limits => {
                :limit_memory => 2
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['limits']['limit_memory']).to eq(data[:limits][:limit_memory])
  end

  it "Edit 'RAM' limit 'Max' value, set 0 (Unlimited)" do
    data = {:limits => {
                :limit_memory => 0
            }
    }
    @br.edit_base_resource(@bp_id, @br.br_id, data)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response['limits']['limit_memory']).to eq(data[:limits][:limit_memory])
  end

  it "Delete 'RAM' limit resource" do
    @br.delete_base_resource(@bp_id, @br.br_id)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response.first).to eq('Resource not found')
  end
########################################################################################################################
  # Check 'Prices On'
  it "Create 'RAM' limit with negative 'Price On' value" do 
    data = {:resource_class => "Billing::Resource::HypervisorGroup",
            :target_id => @hvz_id,
            :target_type => "Pack",
            :prices => {
                :price_on_memory => -2
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['price_on_memory'].first).to eq("must be greater than or equal to 0")
  end

  it "Create 'RAM' limit with pozitive 'Price On' value > 0" do
    data = {:resource_class => "Billing::Resource::HypervisorGroup",
            :target_id => @hvz_id,
            :target_type => "Pack",
            :prices => {
                :price_on_memory => 2
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['prices']['price_on_memory']).to eq(data[:prices][:price_on_memory].to_f)
  end

  it "Edit 'RAM' limit 'Price On' value, set 0" do
    data = {:prices => {
        :price_on_memory => 0
    }
    }
    @br.edit_base_resource(@bp_id, @br.br_id, data)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response['prices']['price_on_memory']).to eq(data[:prices][:price_on_memory])
  end

  it "Delete 'RAM' limit resource" do
    @br.delete_base_resource(@bp_id, @br.br_id)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response.first).to eq('Resource not found')
  end
########################################################################################################################
  # Check 'Prices Off'
  it "Create 'RAM' limit with negative 'Price Off' value" do 
    data = {:resource_class => "Billing::Resource::HypervisorGroup",
            :target_id => @hvz_id,
            :target_type => "Pack",
            :prices => {
                :price_off_memory => -2
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['price_off_memory'].first).to eq("must be greater than or equal to 0")
  end

  it "Create 'RAM' limit with pozitive 'Price Off' value > 0" do
    data = {:resource_class => "Billing::Resource::HypervisorGroup",
            :target_id => @hvz_id,
            :target_type => "Pack",
            :prices => {
                :price_off_memory => 2
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['prices']['price_off_memory']).to eq(data[:prices][:price_off_memory].to_f)
  end

  it "Edit 'RAM' limit 'Price Off' value, set 0" do
    data = {:prices => {
        :price_off_memory => 0
    }
    }
    @br.edit_base_resource(@bp_id, @br.br_id, data)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response['prices']['price_off_memory']).to eq(data[:prices][:price_off_memory])
  end

  it "Delete 'RAM' limit resource" do
    @br.delete_base_resource(@bp_id, @br.br_id)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response.first).to eq('Resource not found')
  end
########################################################################################################################
  # VS creation properties
########################################################################################################################
  # CPU Cores
  it "Create limit with negative 'Min' value for CPU Cores" do
    data = {:resource_class => "Billing::Resource::HypervisorGroup",
            :target_id => @hvz_id,
            :target_type => "Pack",
            :limits => {
                :limit_min_cpu => -2
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['limit_min_cpu'].first).to eq("must be greater than or equal to 1")
  end

  it "Create limit with pozitive 'Min' value for CPU Cores" do 
    data = {:resource_class => "Billing::Resource::HypervisorGroup",
            :target_id => @hvz_id,
            :target_type => "Pack",
            :limits => {
                :limit_min_cpu => 2
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['limits']['limit_min_cpu']).to eq(data[:limits][:limit_min_cpu])
  end

  it "Edit limit 'Min' value for CPU Cores, set 5" do
    data = {:limits => {
                :limit_min_cpu => 5
            }
    }
    @br.edit_base_resource(@bp_id, @br.br_id, data)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response['limits']['limit_min_cpu']).to eq(data[:limits][:limit_min_cpu])
  end

  it "Delete limit resource" do
    @br.delete_base_resource(@bp_id, @br.br_id)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response.first).to eq('Resource not found')
  end
########################################################################################################################
  it "Create limit with negative 'Default values' value for CPU Cores" do 
    data = {:resource_class => "Billing::Resource::HypervisorGroup",
            :target_id => @hvz_id,
            :target_type => "Pack",
            :limits => {
                :limit_default_cpu => -2
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['limit_default_cpu'].first).to eq("must be greater than or equal to 1")
  end

  it "Create limit with pozitive 'Default values' value for CPU Cores" do 
    data = {:resource_class => "Billing::Resource::HypervisorGroup",
            :target_id => @hvz_id,
            :target_type => "Pack",
            :limits => {
                :limit_default_cpu => 2
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['limits']['limit_default_cpu']).to eq(data[:limits][:limit_default_cpu])
  end

  it "Edit limit 'Default values' value for CPU Cores, set 5" do
    data = {:limits => {
                :limit_default_cpu => 5
            }
    }
    @br.edit_base_resource(@bp_id, @br.br_id, data)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response['limits']['limit_default_cpu']).to eq(data[:limits][:limit_default_cpu])
  end
########################################################################################################################
  it "Check 'Use default values?' switcher for CPU." do
    data = {:preferences => {
        :use_default_cpu => true
    }
    }
    @br.edit_base_resource(@bp_id, @br.br_id, data)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response['preferences']['use_default_cpu']).to eq(data[:preferences][:use_default_cpu])
  end

  it "Delete limit resource" do
    @br.delete_base_resource(@bp_id, @br.br_id)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response.first).to eq('Resource not found')
  end
########################################################################################################################
  # CPU Priority
  it "Create limit with negative 'Min' value for CPU Priority" do
    data = {:resource_class => "Billing::Resource::HypervisorGroup",
            :target_id => @hvz_id,
            :target_type => "Pack",
            :limits => {
                :limit_min_cpu_priority => -2
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['limit_min_cpu_priority'].first).to eq("must be greater than or equal to 1")
  end

  it "Create limit with pozitive 'Min' value for CPU Priority" do 
    data = {:resource_class => "Billing::Resource::HypervisorGroup",
            :target_id => @hvz_id,
            :target_type => "Pack",
            :limits => {
                :limit_min_cpu_priority => 2
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['limits']['limit_min_cpu_priority']).to eq(data[:limits][:limit_min_cpu_priority].to_f)
  end

  it "Edit limit 'Min' value for CPU Priority, set 5" do
    data = {:limits => {
                :limit_min_cpu_priority => 5
            }
    }
    @br.edit_base_resource(@bp_id, @br.br_id, data)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response['limits']['limit_min_cpu_priority']).to eq(data[:limits][:limit_min_cpu_priority])
  end

  it "Delete limit resource" do
    @br.delete_base_resource(@bp_id, @br.br_id)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response.first).to eq('Resource not found')
  end
########################################################################################################################
  it "Create limit with negative 'Default values' value for CPU Priority" do
    data = {:resource_class => "Billing::Resource::HypervisorGroup",
            :target_id => @hvz_id,
            :target_type => "Pack",
            :limits => {
                :limit_default_cpu_share => -2
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['limit_default_cpu_share'].first).to eq("must be greater than or equal to 1")
  end

  it "Create limit with pozitive 'Default values' value for CPU Priority" do 
    data = {:resource_class => "Billing::Resource::HypervisorGroup",
            :target_id => @hvz_id,
            :target_type => "Pack",
            :limits => {
                :limit_default_cpu_share => 2
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['limits']['limit_default_cpu_share']).to eq(data[:limits][:limit_default_cpu_share].to_f)
  end

  it "Edit limit 'Default values' value for CPU Priority, set 5" do
    data = {:limits => {
                :limit_default_cpu_share => 5
            }
    }
    @br.edit_base_resource(@bp_id, @br.br_id, data)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response['limits']['limit_default_cpu_share']).to eq(data[:limits][:limit_default_cpu_share])
  end
########################################################################################################################
  it "Check 'Use default values?' switcher for CPU Share." do
    data = {:preferences => {
        :use_default_cpu_share => "true"
    }
    }
    @br.edit_base_resource(@bp_id, @br.br_id, data)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response['preferences']['use_default_cpu_share'].to_s).to eq(data[:preferences][:use_default_cpu_share])
  end

  it "Delete limit resource" do
    @br.delete_base_resource(@bp_id, @br.br_id)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response.first).to eq('Resource not found')
  end
########################################################################################################################
  # RAM
  it "Create limit with negative 'Min values' value for RAM" do
    data = {:resource_class => "Billing::Resource::HypervisorGroup",
            :target_id => @hvz_id,
            :target_type => "Pack",
            :limits => {
                :limit_min_memory => -2
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['limit_min_memory'].first).to eq("must be greater than or equal to 128")
  end

  it "Create limit with pozitive 'Min values' value for RAM" do
    data = {:resource_class => "Billing::Resource::HypervisorGroup",
            :target_id => @hvz_id,
            :target_type => "Pack",
            :limits => {
                :limit_min_memory => 256
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['limits']['limit_min_memory']).to eq(data[:limits][:limit_min_memory])
  end

  it "Edit limit 'Min values' value for RAM, set 512" do
    data = {:limits => {
                :limit_min_memory => 512
            }
    }
    @br.edit_base_resource(@bp_id, @br.br_id, data)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response['limits']['limit_min_memory']).to eq(data[:limits][:limit_min_memory])
  end

########################################################################################################################
  it "Check 'Use Master Bucket Zone?' switcher." do
    data = {:in_bucket_zone => "true"}
    @br.edit_base_resource(@bp_id, @br.br_id, data)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response['in_bucket_zone'].to_s).to eq(data[:in_bucket_zone])
  end
########################################################################################################################
  it "Delete limit resource" do
    @br.delete_base_resource(@bp_id, @br.br_id)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response.first).to eq('Resource not found')
  end
end
