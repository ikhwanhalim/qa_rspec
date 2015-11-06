# Check Customer Network Limits
require './lib/onapp_base_resource'

describe "Check Customer Network Limits" do

  before(:all) do
    @bp = OnappBilling.new
    @br = OnappBaseResource.new
    # Create BP before testing
    @bp.create_billing_plan({:label => 'TestBPForBaseResources'})
    @bp_id = @bp.bp_id
  end

  after(:all) do
    @bp.delete_billing_plan()
  end
########################################################################################################################
# Check 'Free' limits
  it "Create with negative 'Free' value" do
    data = {:resource_class => "Billing::Resource::CustomerNetwork",
            :limits => {
                :limit_free => -2
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['limit_free'].first).to eq("must be greater than or equal to 0")
  end

  it "Create with pozitive 'Free' value > 0" do
    data = {:resource_class => "Billing::Resource::CustomerNetwork",
            :limits => {
                :limit_free => 2
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['limits']['limit_free']).to eq(data[:limits][:limit_free])
  end

  it "Edit 'Free' value, set 0" do
    data = {:limits => {
        :limit_free => 0
    }
    }
    @br.edit_base_resource(@bp_id, @br.br_id, data)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response['limits']['limit_free']).to eq(data[:limits][:limit_free])
  end

  it "Delete resource" do
    @br.delete_base_resource(@bp_id, @br.br_id)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response.first).to eq('Resource not found')
  end
########################################################################################################################
# Check 'Max' limits
  it "Create with negative 'Max' value" do
    data = {:resource_class => "Billing::Resource::CustomerNetwork",
            :limits => {
                :limit => -2
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['limit'].first).to eq("must be greater than or equal to 0")
  end
  it "Create with pozitive 'Max' value > 0" do
    data = {:resource_class => "Billing::Resource::CustomerNetwork",
            :limits => {
                :limit => 2
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['limits']['limit']).to eq(data[:limits][:limit])
  end
  it "Edit 'Max' value, set 0 (Unlimited)" do
    data = {:limits => {
        :limit => 0
    }
    }
    @br.edit_base_resource(@bp_id, @br.br_id, data)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response['limits']['limit']).to eq(data[:limits][:limit])
  end
  it "Delete resource" do
    @br.delete_base_resource(@bp_id, @br.br_id)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response.first).to eq('Resource not found')
  end
########################################################################################################################
# Check 'Prices'
  it "Create with negative 'Price' value" do
    data = {:resource_class => "Billing::Resource::CustomerNetwork",
            :prices => {
                :price => -2
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['price'].first).to eq("must be greater than or equal to 0")
  end
  it "Create with pozitive 'Price' value > 0" do
    data = {:resource_class => "Billing::Resource::CustomerNetwork",
            :prices => {
                :price => 2
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['prices']['price']).to eq(data[:prices][:price].to_f)
  end
  it "Edit 'Price' value, set 0" do
    data = {:prices => {
        :price => 0
    }
    }
    @br.edit_base_resource(@bp_id, @br.br_id, data)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response['prices']['price']).to eq(data[:prices][:price])
  end
  it "Delete resource" do
    @br.delete_base_resource(@bp_id, @br.br_id)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response.first).to eq('Resource not found')
  end
end