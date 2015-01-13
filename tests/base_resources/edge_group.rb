# Check resources for Edge Group
require './lib/onapp_base_resource'

describe "Check resources for Edge Group" do
  before(:all) do
    # Get real EdgeGroup id
    @bp = OnappBilling.new
    @br = OnappBaseResource.new
    # Create BP before testing
    @bp.create_billing_plan({:label => 'TestBPForBaseResources'})
    @bp_id = @bp.bp_id
    @edge_group_id = @br.get_zone_id(type = :edge)
    puts @edge_group_id
  end

  after(:all) do
    @bp.delete_billing_plan()
  end
########################################################################################################################
  it "Create Edge Group limit with unexisted edge group id" do 
    data = {:resource_class => "Resource::EdgeGroup",
            :target_id => 0,
            :target_type => "EdgeGroup"
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['base'].first).to eq("Target not found")
  end

  it "Create Edge Group limit with existed edge group id" do
    data = {:resource_class => "Resource::EdgeGroup",
            :target_id => @edge_group_id,
            :target_type => "EdgeGroup"
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['target_id']).to eq(data[:target_id])
  end
########################################################################################################################
  # Check 'Prices'
  it "Edit, set negative 'Price' value" do
    data = {:price => "-2"}
    response = @br.edit_base_resource(@bp_id, @br.br_id, data)
    expect(response).to eq("Price Data must be greater than or equal to 0")
  end

  it "Edit, set pozitive 'Price' value > 0" do
    data = {:price => 2.0}
    @br.edit_base_resource(@bp_id, @br.br_id, data)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response['prices']['price']).to eq(data[:price])
  end

  it "Edit, set 'Price' value equal 0" do
    data = {:price => 0.0}
    @br.edit_base_resource(@bp_id, @br.br_id, data)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response['prices']['price']).to eq(data[:price])
  end

  it "Delete Edge Group resource" do
    data = {:force => true}
    @br.delete_base_resource(@bp_id, @br.br_id, data)
    attempt = 0
    while attempt < 10 do
      response = @br.get_base_resource(@bp_id, @br.br_id)
      break if response.first == 'BaseResource not found'
      attempt += 1
      sleep(1)
    end
    expect(response.first).to eq('BaseResource not found')
  end
end
