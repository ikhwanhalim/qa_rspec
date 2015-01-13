# Check Network Zones limits
require './lib/onapp_base_resource'

describe "Check Network Zones limits" do
########################################################################################################################
  before(:all) do
    # Get real BackupServerZone id
    @bp = OnappBilling.new
    @br = OnappBaseResource.new
    # Create BP before testing
    @bp.create_billing_plan({:label => 'TestBPForBaseResources'})
    @bp_id = @bp.bp_id
    @ntwz_id = @br.get_zone_id(type = :network)
  end

  after(:all) do
    @bp.delete_billing_plan()
  end
########################################################################################################################
  it "Create Network Zones limit with unexisted network zones id" do
    data = {:resource_class => "Resource::NetworkGroup",
            :target_id => 0,
            :target_type => "Pack"
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['base'].first).to eq("Target not found")
  end
########################################################################################################################
  # Check 'IP Address' limits
########################################################################################################################
  # Check 'Free' limits
  it "Create 'IP Address' limit with negative 'Free' value" do 
    data = {:resource_class => "Resource::NetworkGroup",
            :target_id => @ntwz_id,
            :target_type => "Pack",
            :limits => {
                :limit_ip_free => "-2"
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['limit_ip_free'].first).to eq("must be greater than or equal to 0")
  end

  it "Create 'IP Address' limit with pozitive 'Free' value > 0" do 
    data = {:resource_class => "Resource::NetworkGroup",
            :target_id => @ntwz_id,
            :target_type => "Pack",
            :limits => {
                :limit_ip_free => "2"
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['limits']['limit_ip_free']).to eq(data[:limits][:limit_ip_free])
  end

  it "Edit 'IP Address' limit 'Free' value, set 0" do
    data = {:limits => {
                :limit_ip_free => "0"
            }
    }
    @br.edit_base_resource(@bp_id, @br.br_id, data)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response['limits']['limit_ip_free'].to_s).to eq(data[:limits][:limit_ip_free])
  end

  it "Delete 'IP Address' limit resource" do
    @br.delete_base_resource(@bp_id, @br.br_id)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response.first).to eq('BaseResource not found')
  end
########################################################################################################################
  # Check 'Max' limits
  it "Create 'IP Address' limit with negative 'Max' value" do 
    data = {:resource_class => "Resource::NetworkGroup",
            :target_id => @ntwz_id,
            :target_type => "Pack",
            :limits => {
                :limit_ip => "-2"
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['limit_ip'].first).to eq("must be greater than or equal to 0")
  end

  it "Create 'IP Address' limit with pozitive 'Max' value > 0" do 
    data = {:resource_class => "Resource::NetworkGroup",
            :target_id => @ntwz_id,
            :target_type => "Pack",
            :limits => {
                :limit_ip => "2"
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['limits']['limit_ip']).to eq(data[:limits][:limit_ip])
  end

  it "Edit 'IP Address' limit 'Max' value, set 0 (Unlimited)" do
    data = {:limits => {
                :limit_ip => "0"
            }
    }
    @br.edit_base_resource(@bp_id, @br.br_id, data)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response['limits']['limit_ip'].to_s).to eq(data[:limits][:limit_ip])
  end

  it "Delete 'IP Address' limit resource" do
    @br.delete_base_resource(@bp_id, @br.br_id)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response.first).to eq('BaseResource not found')
  end
########################################################################################################################
  # Check 'Prices On'
  it "Create 'IP Address' limit with negative 'Price On' value" do 
    data = {:resource_class => "Resource::NetworkGroup",
            :target_id => @ntwz_id,
            :target_type => "Pack",
            :prices => {
                :price_ip_on => "-2"
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['price_ip_on'].first).to eq("must be greater than or equal to 0")
  end

  it "Create 'IP Address' limit with pozitive 'Price On' value > 0" do 
    data = {:resource_class => "Resource::NetworkGroup",
            :target_id => @ntwz_id,
            :target_type => "Pack",
            :prices => {
                :price_ip_on => "2"
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['prices']['price_ip_on']).to eq("$#{data[:prices][:price_ip_on]}.00 per IP /hr")
  end

  it "Edit 'IP Address' limit 'Price On' value, set 0" do
    data = {:prices => {
        :price_ip_on => 0
    }
    }
    @br.edit_base_resource(@bp_id, @br.br_id, data)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response['prices']['price_ip_on']).to eq(data[:prices][:price_ip_on])
  end

  it "Delete 'IP Address' limit resource" do
    @br.delete_base_resource(@bp_id, @br.br_id)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response.first).to eq('BaseResource not found')
  end
########################################################################################################################
  # Check 'Prices Off'
  it "Create 'IP Address' limit with negative 'Price Off' value" do 
    data = {:resource_class => "Resource::NetworkGroup",
            :target_id => @ntwz_id,
            :target_type => "Pack",
            :prices => {
                :price_ip_off => "-2"
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['price_ip_off'].first).to eq("must be greater than or equal to 0")
  end

  it "Create 'IP Address' limit with pozitive 'Price Off' value > 0" do 
    data = {:resource_class => "Resource::NetworkGroup",
            :target_id => @ntwz_id,
            :target_type => "Pack",
            :prices => {
                :price_ip_off => "2"
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['prices']['price_ip_off']).to eq("$#{data[:prices][:price_ip_off]}.00 per IP /hr")
  end

  it "Edit 'IP Address' limit 'Price Off' value, set 0" do
    data = {:prices => {
        :price_ip_off => 0
    }
    }
    @br.edit_base_resource(@bp_id, @br.br_id, data)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response['prices']['price_ip_off']).to eq(data[:prices][:price_ip_off])
  end

  it "Delete 'IP Address' limit resource" do
    @br.delete_base_resource(@bp_id, @br.br_id)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response.first).to eq('BaseResource not found')
  end
########################################################################################################################
  # Check 'Port Speed' limits
########################################################################################################################
  # Check 'Free' limits
  it "Create 'Port Speed' limit with negative 'Free' value" do 
    data = {:resource_class => "Resource::NetworkGroup",
            :target_id => @ntwz_id,
            :target_type => "Pack",
            :limits => {
                :limit_rate_free => "-2"
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['limit_rate_free'].first).to eq("must be greater than or equal to 0")
  end

  it "Create 'Port Speed' limit with pozitive 'Free' value > 0" do 
    data = {:resource_class => "Resource::NetworkGroup",
            :target_id => @ntwz_id,
            :target_type => "Pack",
            :limits => {
                :limit_rate_free => "2"
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['limits']['limit_rate_free']).to eq("#{data[:limits][:limit_rate_free]} Mb per second")
  end

  it "Edit 'Port Speed' limit 'Free' value, set 0" do
    data = {:limits => {
                :limit_rate_free => "0"
            }
    }
    @br.edit_base_resource(@bp_id, @br.br_id, data)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response['limits']['limit_rate_free'].to_s).to eq(data[:limits][:limit_rate_free])
  end

  it "Delete 'Port Speed' limit resource" do
    @br.delete_base_resource(@bp_id, @br.br_id)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response.first).to eq('BaseResource not found')
  end
########################################################################################################################
  # Check 'Max' limits
  it "Create 'Port Speed' limit with negative 'Max' value" do 
    data = {:resource_class => "Resource::NetworkGroup",
            :target_id => @ntwz_id,
            :target_type => "Pack",
            :limits => {
                :limit_rate => "-2"
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['limit_rate'].first).to eq("must be greater than or equal to 1")
  end

  it "Create 'Port Speed' limit with pozitive 'Max' value > 0" do 
    data = {:resource_class => "Resource::NetworkGroup",
            :target_id => @ntwz_id,
            :target_type => "Pack",
            :limits => {
                :limit_rate => "2"
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['limits']['limit_rate']).to eq("#{data[:limits][:limit_rate]} Mb per second")
  end

  it "Edit 'Port Speed' limit 'Max' value, set as empty (Unlimited)" do
    data = {:limits => {
                :limit_rate => ""
            }
    }
    @br.edit_base_resource(@bp_id, @br.br_id, data)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response['limits']['limit_rate'].to_s).to eq(data[:limits][:limit_rate])
  end

  it "Delete 'Port Speed' limit resource" do
    @br.delete_base_resource(@bp_id, @br.br_id)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response.first).to eq('BaseResource not found')
  end
########################################################################################################################
  # Check 'Prices On'
  it "Create 'Port Speed' limit with negative 'Price On' value" do 
    data = {:resource_class => "Resource::NetworkGroup",
            :target_id => @ntwz_id,
            :target_type => "Pack",
            :prices => {
                :price_rate_on => "-2"
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['price_rate_on'].first).to eq("must be greater than or equal to 0")
  end

  it "Create 'Port Speed' limit with pozitive 'Price On' value > 0" do 
    data = {:resource_class => "Resource::NetworkGroup",
            :target_id => @ntwz_id,
            :target_type => "Pack",
            :prices => {
                :price_rate_on => "2"
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['prices']['price_rate_on']).to eq("$#{data[:prices][:price_rate_on]}.00 per Mbps /hr")
  end

  it "Edit 'Port Speed' limit 'Price On' value, set 0" do
    data = {:prices => {
        :price_rate_on => 0
    }
    }
    @br.edit_base_resource(@bp_id, @br.br_id, data)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response['prices']['price_rate_on']).to eq(data[:prices][:price_rate_on])
  end

  it "Delete 'Port Speed' limit resource" do
    @br.delete_base_resource(@bp_id, @br.br_id)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response.first).to eq('BaseResource not found')
  end
########################################################################################################################
  # Check 'Prices Off'
  it "Create 'Port Speed' limit with negative 'Price Off' value" do 
    data = {:resource_class => "Resource::NetworkGroup",
            :target_id => @ntwz_id,
            :target_type => "Pack",
            :prices => {
                :price_rate_off => "-2"
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['price_rate_off'].first).to eq("must be greater than or equal to 0")
  end

  it "Create 'Port Speed' limit with pozitive 'Price Off' value > 0" do 
    data = {:resource_class => "Resource::NetworkGroup",
            :target_id => @ntwz_id,
            :target_type => "Pack",
            :prices => {
                :price_rate_off => "2"
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['prices']['price_rate_off']).to eq("$#{data[:prices][:price_rate_off]}.00 per Mbps /hr")
  end

  it "Edit 'Port Speed' limit 'Price Off' value, set 0" do
    data = {:prices => {
        :price_rate_off => 0
    }
    }
    @br.edit_base_resource(@bp_id, @br.br_id, data)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response['prices']['price_rate_off']).to eq(data[:prices][:price_rate_off])
  end

  it "Delete 'Port Speed' limit resource" do
    @br.delete_base_resource(@bp_id, @br.br_id)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response.first).to eq('BaseResource not found')
  end
########################################################################################################################
  # Check 'Data Received' limits
########################################################################################################################
  # Check 'Free' limits
  it "Create 'Data Received' limit with negative 'Free' value" do 
    data = {:resource_class => "Resource::NetworkGroup",
            :target_id => @ntwz_id,
            :target_type => "Pack",
            :limits => {
                :limit_data_received_free => "-2"
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['limit_data_received_free'].first).to eq("must be greater than or equal to 0")
  end

  it "Create 'Data Received' limit with pozitive 'Free' value > 0" do 
    data = {:resource_class => "Resource::NetworkGroup",
            :target_id => @ntwz_id,
            :target_type => "Pack",
            :limits => {
                :limit_data_received_free => "2"
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['limits']['limit_data_received_free']).to eq("#{data[:limits][:limit_data_received_free]} GB")
  end

  it "Edit 'Data Received' limit 'Free' value, set 0" do
    data = {:limits => {
                :limit_data_received_free => "0"
            }
    }
    @br.edit_base_resource(@bp_id, @br.br_id, data)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response['limits']['limit_data_received_free'].to_s).to eq(data[:limits][:limit_data_received_free])
  end

  it "Delete 'Data Received' limit resource" do
    @br.delete_base_resource(@bp_id, @br.br_id)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response.first).to eq('BaseResource not found')
  end
########################################################################################################################
  # Check 'Prices'
  it "Create 'Data Received' limit with negative 'Price' value" do 
    data = {:resource_class => "Resource::NetworkGroup",
            :target_id => @ntwz_id,
            :target_type => "Pack",
            :prices => {
                :price_data_received => "-2"
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['price_data_received'].first).to eq("must be greater than or equal to 0")
  end

  it "Create 'Data Received' limit with pozitive 'Price' value > 0" do 
    data = {:resource_class => "Resource::NetworkGroup",
            :target_id => @ntwz_id,
            :target_type => "Pack",
            :prices => {
                :price_data_received => "2"
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['prices']['price_data_received']).to eq("$#{data[:prices][:price_data_received]}.00 per GB /hr")
  end

  it "Edit 'Data Received' limit 'Price' value, set 0" do
    data = {:prices => {
        :price_data_received => 0
    }
    }
    @br.edit_base_resource(@bp_id, @br.br_id, data)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response['prices']['price_data_received']).to eq(data[:prices][:price_data_received])
  end

  it "Delete 'Data Received' limit resource" do
    @br.delete_base_resource(@bp_id, @br.br_id)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response.first).to eq('BaseResource not found')
  end
########################################################################################################################
  # Check 'Data Sent' limits
########################################################################################################################
  # Check 'Free' limits
  it "Create 'Data Sent' limit with negative 'Free' value" do 
    data = {:resource_class => "Resource::NetworkGroup",
            :target_id => @ntwz_id,
            :target_type => "Pack",
            :limits => {
                :limit_data_sent_free => "-2"
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['limit_data_sent_free'].first).to eq("must be greater than or equal to 0")
  end

  it "Create 'Data Sent' limit with pozitive 'Free' value > 0" do 
    data = {:resource_class => "Resource::NetworkGroup",
            :target_id => @ntwz_id,
            :target_type => "Pack",
            :limits => {
                :limit_data_sent_free => "2"
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['limits']['limit_data_sent_free']).to eq("#{data[:limits][:limit_data_sent_free]} GB")
  end

  it "Edit 'Data Sent' limit 'Free' value, set 0" do
    data = {:limits => {
                :limit_data_sent_free => "0"
            }
    }
    @br.edit_base_resource(@bp_id, @br.br_id, data)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response['limits']['limit_data_sent_free'].to_s).to eq(data[:limits][:limit_data_sent_free])
  end

  it "Delete 'Data Sent' limit resource" do
    @br.delete_base_resource(@bp_id, @br.br_id)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response.first).to eq('BaseResource not found')
  end
########################################################################################################################
  # Check 'Prices'
  it "Create 'Data Sent' limit with negative 'Price' value" do 
    data = {:resource_class => "Resource::NetworkGroup",
            :target_id => @ntwz_id,
            :target_type => "Pack",
            :prices => {
                :price_data_sent => "-2"
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['price_data_sent'].first).to eq("must be greater than or equal to 0")
  end

  it "Create 'Data Sent' limit with pozitive 'Price' value > 0" do 
    data = {:resource_class => "Resource::NetworkGroup",
            :target_id => @ntwz_id,
            :target_type => "Pack",
            :prices => {
                :price_data_sent => "2"
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['prices']['price_data_sent']).to eq("$#{data[:prices][:price_data_sent]}.00 per GB /hr")
  end

  it "Edit 'Data Sent' limit 'Price' value, set 0" do
    data = {:prices => {
        :price_data_sent => 0
    }
    }
    @br.edit_base_resource(@bp_id, @br.br_id, data)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response['prices']['price_data_sent']).to eq(data[:prices][:price_data_sent])
  end
########################################################################################################################
  it "Check Use Master Template Zone? switcher." do
    data = {:in_template_zone => "true"}
    @br.edit_base_resource(@bp_id, @br.br_id, data)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response['in_template_zone'].to_s).to eq(data[:in_template_zone])
  end
########################################################################################################################
  it "Delete 'Data Sent' limit resource" do
    @br.delete_base_resource(@bp_id, @br.br_id)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response.first).to eq('BaseResource not found')
  end
end
