# Check DataStore Zones limits
require './lib/onapp_base_resource'

describe "Check DataStore Zones limits" do
  before(:all) do
    # Get real DatastoreZone id
    @bp = OnappBilling.new
    @br = OnappBaseResource.new
    # Create BP before testing
    @bp.create_billing_plan({:label => 'TestBPForBaseResources'})
    @bp_id = @bp.bp_id
    @dsz_id = @br.get_zone_id(type = :store)
    puts @dsz_id
  end

  after(:all) do
    @bp.delete_billing_plan()
  end
########################################################################################################################
  it "Create DataStore Zones limit with unexisted data store zones id" do
    data = {:resource_class => "Billing::Resource::DataStoreGroup",
            :target_id => 0,
            :target_type => "Pack"
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['base'].first).to eq("Target not found")
  end
########################################################################################################################
  # Check 'Disk Size' limits
########################################################################################################################
  # Check 'Free' limits
  it "Create 'Disk Size' limit with negative 'Free' value" do
    data = {:resource_class => "Billing::Resource::DataStoreGroup",
            :target_id => @dsz_id,
            :target_type => "Pack",
            :limits => {
                :limit_free => -2
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['limit_free'].first).to eq("must be greater than or equal to 0")
  end

  it "Create 'Disk Size' limit with pozitive 'Free' value > 0" do 
    data = {:resource_class => "Billing::Resource::DataStoreGroup",
            :target_id => @dsz_id,
            :target_type => "Pack",
            :limits => {
                :limit_free => 2
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['limits']['limit_free']).to eq(data[:limits][:limit_free].to_f)
  end

  it "Edit 'Disk Size' limit 'Free' value, set 0" do
    data = {:limits => {
                :limit_free => 20
            }
    }
    @br.edit_base_resource(@bp_id, @br.br_id, data)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response['limits']['limit_free']).to eq(data[:limits][:limit_free])
  end

  it "Delete 'Disk Size' limit resource" do
    @br.delete_base_resource(@bp_id, @br.br_id)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response.first).to eq('Resource not found')
  end
########################################################################################################################
  # Check 'Max' limits
  it "Create 'Disk Size' limit with negative 'Max' value" do 
    data = {:resource_class => "Billing::Resource::DataStoreGroup",
            :target_id => @dsz_id,
            :target_type => "Pack",
            :limits => {
                :limit => -2
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['limit'].first).to eq("must be greater than or equal to 0")
  end

  it "Create 'Disk Size' limit with pozitive 'Max' value > 0" do 
    data = {:resource_class => "Billing::Resource::DataStoreGroup",
            :target_id => @dsz_id,
            :target_type => "Pack",
            :limits => {
                :limit => 2
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['limits']['limit']).to eq(data[:limits][:limit].to_f)
  end

  it "Edit 'Disk Size' limit 'Max' value, set 0 (Unlimited)" do
    data = {:limits => {
                :limit => 20
            }
    }
    @br.edit_base_resource(@bp_id, @br.br_id, data)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response['limits']['limit']).to eq(data[:limits][:limit])
  end

  it "Delete 'Disk Size' limit resource" do
    @br.delete_base_resource(@bp_id, @br.br_id)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response.first).to eq('Resource not found')
  end
########################################################################################################################
  # Check 'Prices On'
  it "Create 'Disk Size' limit with negative 'Price On' value" do 
    data = {:resource_class => "Billing::Resource::DataStoreGroup",
            :target_id => @dsz_id,
            :target_type => "Pack",
            :prices => {
                :price_on => -2
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['price_on'].first).to eq("must be greater than or equal to 0")
  end

  it "Create 'Disk Size' limit with pozitive 'Price On' value > 0" do 
    data = {:resource_class => "Billing::Resource::DataStoreGroup",
            :target_id => @dsz_id,
            :target_type => "Pack",
            :prices => {
                :price_on => 2
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['prices']['price_on']).to eq(data[:prices][:price_on].to_f)
  end

  it "Edit 'Disk Size' limit 'Price On' value, set 0" do
    data = {:prices => {
                :price_on => 20
            }
    }
    @br.edit_base_resource(@bp_id, @br.br_id, data)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response['prices']['price_on']).to eq(data[:prices][:price_on])
  end

  it "Delete 'Disk Size' limit resource" do
    @br.delete_base_resource(@bp_id, @br.br_id)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response.first).to eq('Resource not found')
  end
########################################################################################################################
  # Check 'Prices Off'
  it "Create 'Disk Size' limit with negative 'Price Off' value" do 
    data = {:resource_class => "Billing::Resource::DataStoreGroup",
            :target_id => @dsz_id,
            :target_type => "Pack",
            :prices => {
                :price_off => -2
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['price_off'].first).to eq("must be greater than or equal to 0")
  end

  it "Create 'Disk Size' limit with pozitive 'Price Off' value > 0" do 
    data = {:resource_class => "Billing::Resource::DataStoreGroup",
            :target_id => @dsz_id,
            :target_type => "Pack",
            :prices => {
                :price_off => 2
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['prices']['price_off']).to eq(data[:prices][:price_off].to_f)
  end

  it "Edit 'Disk Size' limit 'Price Off' value, set 0" do
    data = {:prices => {
                :price_off => 20
            }
    }
    @br.edit_base_resource(@bp_id, @br.br_id, data)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response['prices']['price_off']).to eq(data[:prices][:price_off])
  end

  it "Delete 'Disk Size' limit resource" do
    @br.delete_base_resource(@bp_id, @br.br_id)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response.first).to eq('Resource not found')
  end
########################################################################################################################
  # Check 'Data Read' limits
########################################################################################################################
  # Check 'Free' limits
  it "Create 'Data Read' limit with negative 'Free' value" do 
    data = {:resource_class => "Billing::Resource::DataStoreGroup",
            :target_id => @dsz_id,
            :target_type => "Pack",
            :limits => {
                :limit_data_read_free => -2
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['limit_data_read_free'].first).to eq("must be greater than or equal to 0")
  end

  it "Create 'Data Read' limit with pozitive 'Free' value > 0" do 
    data = {:resource_class => "Billing::Resource::DataStoreGroup",
            :target_id => @dsz_id,
            :target_type => "Pack",
            :limits => {
                :limit_data_read_free => 2
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['limits']['limit_data_read_free']).to eq(data[:limits][:limit_data_read_free].to_f)
  end

  it "Edit 'Data Read' limit 'Free' value, set 0" do
    data = {:limits => {
                :limit_data_read_free => 20
            }
    }
    @br.edit_base_resource(@bp_id, @br.br_id, data)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response['limits']['limit_data_read_free']).to eq(data[:limits][:limit_data_read_free])
  end

  it "Delete 'Data Read' limit resource" do
    @br.delete_base_resource(@bp_id, @br.br_id)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response.first).to eq('Resource not found')
  end
########################################################################################################################
  # Check 'Prices'
  it "Create 'Data Read' limit with negative 'Price' value" do 
    data = {:resource_class => "Billing::Resource::DataStoreGroup",
            :target_id => @dsz_id,
            :target_type => "Pack",
            :prices => {
                :price_data_read => -2
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['price_data_read'].first).to eq("must be greater than or equal to 0")
  end

  it "Create 'Data Read' limit with pozitive 'Price' value > 0" do 
    data = {:resource_class => "Billing::Resource::DataStoreGroup",
            :target_id => @dsz_id,
            :target_type => "Pack",
            :prices => {
                :price_data_read => 2
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['prices']['price_data_read']).to eq(data[:prices][:price_data_read].to_f)
  end

  it "Edit 'Data Read' limit 'Price' value, set 0" do
    data = {:prices => {
                :price_data_read => 20
            }
    }
    @br.edit_base_resource(@bp_id, @br.br_id, data)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response['prices']['price_data_read']).to eq(data[:prices][:price_data_read])
  end

  it "Delete 'Data Read' limit resource" do
    @br.delete_base_resource(@bp_id, @br.br_id)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response.first).to eq('Resource not found')
  end
########################################################################################################################
  # Check 'Data Written' limits
########################################################################################################################
  # Check 'Free' limits
  it "Create 'Data Written' limit with negative 'Free' value" do 
    data = {:resource_class => "Billing::Resource::DataStoreGroup",
            :target_id => @dsz_id,
            :target_type => "Pack",
            :limits => {
                :limit_data_written_free => -2
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['limit_data_written_free'].first).to eq("must be greater than or equal to 0")
  end

  it "Create 'Data Written' limit with pozitive 'Free' value > 0" do 
    data = {:resource_class => "Billing::Resource::DataStoreGroup",
            :target_id => @dsz_id,
            :target_type => "Pack",
            :limits => {
                :limit_data_written_free => 2
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['limits']['limit_data_written_free']).to eq(data[:limits][:limit_data_written_free].to_f)
  end

  it "Edit 'Data Written' limit 'Free' value, set 0" do
    data = {:limits => {
                :limit_data_written_free => 20
            }
    }
    @br.edit_base_resource(@bp_id, @br.br_id, data)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response['limits']['limit_data_written_free']).to eq(data[:limits][:limit_data_written_free])
  end

  it "Delete 'Data Written' limit resource" do
    @br.delete_base_resource(@bp_id, @br.br_id)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response.first).to eq('Resource not found')
  end
########################################################################################################################
  # Check 'Prices'
  it "Create 'Data Written' limit with negative 'Price' value" do 
    data = {:resource_class => "Billing::Resource::DataStoreGroup",
            :target_id => @dsz_id,
            :target_type => "Pack",
            :prices => {
                :price_data_written => -2
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['price_data_written'].first).to eq("must be greater than or equal to 0")
  end

  it "Create 'Data Written' limit with pozitive 'Price' value > 0" do 
    data = {:resource_class => "Billing::Resource::DataStoreGroup",
            :target_id => @dsz_id,
            :target_type => "Pack",
            :prices => {
                :price_data_written => 2
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['prices']['price_data_written']).to eq(data[:prices][:price_data_written].to_f)
  end

  it "Edit 'Data Written' limit 'Price' value, set 0" do
    data = {:prices => {
                :price_data_written => 20
            }
    }
    @br.edit_base_resource(@bp_id, @br.br_id, data)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response['prices']['price_data_written']).to eq(data[:prices][:price_data_written])
  end

  it "Delete 'Data Written' limit resource" do
    @br.delete_base_resource(@bp_id, @br.br_id)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response.first).to eq('Resource not found')
  end
########################################################################################################################
  # Check 'Input Requests' limits
########################################################################################################################
  # Check 'Free' limits
  it "Create 'Input Requests' limit with negative 'Free' value" do 
    data = {:resource_class => "Billing::Resource::DataStoreGroup",
            :target_id => @dsz_id,
            :target_type => "Pack",
            :limits => {
                :limit_reads_completed_free => -2
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['limit_reads_completed_free'].first).to eq("must be greater than or equal to 0")
  end

  it "Create 'Input Requests' limit with pozitive 'Free' value > 0" do 
    data = {:resource_class => "Billing::Resource::DataStoreGroup",
            :target_id => @dsz_id,
            :target_type => "Pack",
            :limits => {
                :limit_reads_completed_free => 2
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['limits']['limit_reads_completed_free']).to eq(data[:limits][:limit_reads_completed_free].to_f)
  end

  it "Edit 'Input Requests' limit 'Free' value, set 0" do
    data = {:limits => {
                :limit_reads_completed_free => 20
            }
    }
    @br.edit_base_resource(@bp_id, @br.br_id, data)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response['limits']['limit_reads_completed_free']).to eq(data[:limits][:limit_reads_completed_free])
  end

  it "Delete 'Input Requests' limit resource" do
    @br.delete_base_resource(@bp_id, @br.br_id)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response.first).to eq('Resource not found')
  end
########################################################################################################################
  # Check 'Prices'
  it "Create 'Input Requests' limit with negative 'Price' value" do 
    data = {:resource_class => "Billing::Resource::DataStoreGroup",
            :target_id => @dsz_id,
            :target_type => "Pack",
            :prices => {
                :price_reads_completed => -2
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['price_reads_completed'].first).to eq("must be greater than or equal to 0")
  end

  it "Create 'Input Requests' limit with pozitive 'Price' value > 0" do 
    data = {:resource_class => "Billing::Resource::DataStoreGroup",
            :target_id => @dsz_id,
            :target_type => "Pack",
            :prices => {
                :price_reads_completed => 2
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['prices']['price_reads_completed']).to eq(data[:prices][:price_reads_completed].to_f)
  end

  it "Edit 'Input Requests' limit 'Price' value, set 0" do
    data = {:prices => {
                :price_reads_completed => 20
            }
    }
    @br.edit_base_resource(@bp_id, @br.br_id, data)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response['prices']['price_reads_completed']).to eq(data[:prices][:price_reads_completed])
  end

  it "Delete 'Input Requests' limit resource" do
    @br.delete_base_resource(@bp_id, @br.br_id)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response.first).to eq('Resource not found')
  end
########################################################################################################################
  # Check 'Output Requests' limits
########################################################################################################################
  # Check 'Free' limits
  it "Create 'Output Requests' limit with negative 'Free' value" do 
    data = {:resource_class => "Billing::Resource::DataStoreGroup",
            :target_id => @dsz_id,
            :target_type => "Pack",
            :limits => {
                :limit_writes_completed_free => -2
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['limit_writes_completed_free'].first).to eq("must be greater than or equal to 0")
  end

  it "Create 'Output Requests' limit with pozitive 'Free' value > 0" do 
    data = {:resource_class => "Billing::Resource::DataStoreGroup",
            :target_id => @dsz_id,
            :target_type => "Pack",
            :limits => {
                :limit_writes_completed_free => 2
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['limits']['limit_writes_completed_free']).to eq(data[:limits][:limit_writes_completed_free].to_f)
  end

  it "Edit 'Output Requests' limit 'Free' value, set 0" do
    data = {:limits => {
                :limit_writes_completed_free => 20
            }
    }
    @br.edit_base_resource(@bp_id, @br.br_id, data)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response['limits']['limit_writes_completed_free']).to eq(data[:limits][:limit_writes_completed_free])
  end

  it "Delete 'Output Requests' limit resource" do
    @br.delete_base_resource(@bp_id, @br.br_id)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response.first).to eq('Resource not found')
  end
########################################################################################################################
  # Check 'Prices'
  it "Create 'Output Requests' limit with negative 'Price' value" do 
    data = {:resource_class => "Billing::Resource::DataStoreGroup",
            :target_id => @dsz_id,
            :target_type => "Pack",
            :prices => {
                :price_writes_completed => -2
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['price_writes_completed'].first).to eq("must be greater than or equal to 0")
  end

  it "Create 'Output Requests' limit with pozitive 'Price' value > 0" do 
    data = {:resource_class => "Billing::Resource::DataStoreGroup",
            :target_id => @dsz_id,
            :target_type => "Pack",
            :prices => {
                :price_writes_completed => 2
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['prices']['price_writes_completed']).to eq(data[:prices][:price_writes_completed].to_f)
  end

  it "Edit 'Output Requests' limit 'Price' value, set 0" do
    data = {:prices => {
                :price_writes_completed => 20
            }
    }
    @br.edit_base_resource(@bp_id, @br.br_id, data)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response['prices']['price_writes_completed']).to eq(data[:prices][:price_writes_completed])
  end
########################################################################################################################
  it "Check Use Master Template Zone? switcher." do
    data = {:in_template_zone => true}
    @br.edit_base_resource(@bp_id, @br.br_id, data)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response['in_template_zone']).to eq(data[:in_template_zone])
  end
########################################################################################################################
  it "Delete 'Output Requests' limit resource" do
    @br.delete_base_resource(@bp_id, @br.br_id)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response.first).to eq('Resource not found')
  end
end