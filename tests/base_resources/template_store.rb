# Check resources for Template Store
require './lib/onapp_base_resource'

describe "Check resources for Template Store" do
########################################################################################################################
  before(:all) do
    # Get real BackupServerZone id
    @bp = OnappBilling.new
    @br = OnappBaseResource.new
    # Create BP before testing
    @bp.create_billing_plan({:label => 'TestBPForBaseResources'})
    @bp_id = @bp.bp_id
    @template_store_id = @br.get_zone_id(type = :template)
  end

  after(:all) do
    @bp.delete_billing_plan(@bp_id)
  end
########################################################################################################################
  it "Create Template Store limit with unexisted template store id" do 
    data = {:resource_class => "Resource::TemplateGroup",
            :target_id => 0,
            :target_type => "ImageTemplateGroup"
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['errors']['base'].first).to eq("Target not found")
  end
  it "Create Template Store limit with existed template store id" do 
    data = {:resource_class => "Resource::TemplateGroup",
            :target_id => @template_store_id,
            :target_type => "ImageTemplateGroup"
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['base_resource']['target_id']).to eq(data[:target_id])
  end
  it "Delete Template Store limit resource" do
    @br.delete_base_resource(@bp_id, @br.br_id)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response['errors'].first).to eq('BaseResource not found')
  end
end
