# Check Template Limits
require './lib/onapp_base_resource'

describe "Check Template Limits" do
########################################################################################################################
  before(:all) do
    # Get real BackupServerZone id
    @bp = OnappBilling.new
    @br = OnappBaseResource.new
    # Create BP before testing
    @bp.create_billing_plan({:label => 'TestBPForBaseResources'})
    @bp_id = @bp.bp_id
  end

  after(:all) do
    @bp.delete_billing_plan(@bp_id)
  end
########################################################################################################################
  # Check 'Free' limits
  it "Create with negative 'Free' value" do
    data = {:resource_class => "Resource::Template",
            :limits => {
                :limit_free => "-2"
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['errors']['limit_free'].first).to eq("must be greater than or equal to 0")
  end
  it "Create with pozitive 'Free' value > 0" do
    data = {:resource_class => "Resource::Template",
            :limits => {
                :limit_free => "2"
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['base_resource']['limits']['limit_free']).to eq(data[:limits][:limit_free])
  end
  it "Edit 'Free' value, set 0" do
    data = {:limits => {
        :limit_free => "0"
    }
    }
    @br.edit_base_resource(@bp_id, @br.br_id, data)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response['base_resource']['limits']['limit_free'].to_s).to eq(data[:limits][:limit_free])
  end
  it "Delete resource" do
    @br.delete_base_resource(@bp_id, @br.br_id)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response['errors'].first).to eq('BaseResource not found')
  end
########################################################################################################################
  # Check 'Max' limits
  it "Create with negative 'Max' value" do
    data = {:resource_class => "Resource::Template",
            :limits => {
                :limit => "-2"
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['errors']['limit'].first).to eq("must be greater than or equal to 0")
  end
  it "Create with pozitive 'Max' value > 0" do
    data = {:resource_class => "Resource::Template",
            :limits => {
                :limit => "2"
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['base_resource']['limits']['limit']).to eq(data[:limits][:limit])
  end
  it "Edit 'Max' value, set 0 (Unlimited)" do
    data = {:limits => {
        :limit => "0"
    }
    }
    @br.edit_base_resource(@bp_id, @br.br_id, data)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response['base_resource']['limits']['limit'].to_s).to eq(data[:limits][:limit])
  end
  it "Delete resource" do
    @br.delete_base_resource(@bp_id, @br.br_id)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response['errors'].first).to eq('BaseResource not found')
  end
########################################################################################################################
  # Check 'Prices'
  it "Create with negative 'Price' value" do 
    data = {:resource_class => "Resource::Template",
            :prices => {
                :price => "-2"
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['errors']['price'].first).to eq("must be greater than or equal to 0")
  end
  it "Create with pozitive 'Price' value > 0" do 
    data = {:resource_class => "Resource::Template",
            :prices => {
                :price => "2"
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['base_resource']['prices']['price']).to eq("$#{data[:prices][:price]}.00 /hr")
  end
  it "Edit 'Price' value, set 0" do
    data = {:prices => {
        :price => 0
    }
    }
    @br.edit_base_resource(@bp_id, @br.br_id, data)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response['base_resource']['prices']['price']).to eq(data[:prices][:price])
  end
  it "Delete resource" do
    @br.delete_base_resource(@bp_id, @br.br_id)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response['errors'].first).to eq('BaseResource not found')
  end
end
  