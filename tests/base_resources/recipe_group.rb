# Check resources for Recipe Group
require './lib/onapp_base_resource'

describe "Check resources for Recipe Group" do
########################################################################################################################
  before(:all) do
    # Get real BackupServerZone id
    @bp = OnappBilling.new
    @br = OnappBaseResource.new
    # Create BP before testing
    @bp.create_billing_plan({:label => 'TestBPForBaseResources'})
    @bp_id = @bp.bp_id
    @recipe_group_id = @br.get_zone_id(type = :recipe)
  end

  after(:all) do
    @bp.delete_billing_plan()
  end
########################################################################################################################
  it "Create Recipe Group limit with unexisted recipe group id" do 
    data = {:resource_class => "Resource::RecipeGroup",
            :target_id => 0,
            :target_type => "RecipeGroup"
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['base'].first).to eq("Target not found")
  end
  it "Create Recipe Group limit with existed recipe group id" do 
    data = {:resource_class => "Resource::RecipeGroup",
            :target_id => @recipe_group_id,
            :target_type => "RecipeGroup"
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['target_id']).to eq(data[:target_id])
  end
  it "Delete Recipe Group limit resource" do
    @br.delete_base_resource(@bp_id, @br.br_id)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response.first).to eq('BaseResource not found')
  end
end
