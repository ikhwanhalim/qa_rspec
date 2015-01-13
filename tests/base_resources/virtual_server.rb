# Check resources for Virtual Server
require './lib/onapp_base_resource'

describe "Check resources for Virtual Server" do
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
    @bp.delete_billing_plan()
  end
########################################################################################################################
  it "Create with negative 'Max' value" do 
    data = {:resource_class => "Resource::VmLimit",
            :limits => {
                :limit => "-2"
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['limit'].first).to eq("must be greater than or equal to 0")
  end
  it "Create with pozitive 'Max' value > 0" do 
    data = {:resource_class => "Resource::VmLimit",
            :limits => {
                :limit => "2"
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['limits']['limit']).to eq(data[:limits][:limit])
  end
  it "Edit 'Max' value, set 0 (Unlimited)" do
    data = {:limits => {
        :limit => "0"
    }
    }
    @br.edit_base_resource(@bp_id, @br.br_id, data)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response['limits']['limit'].to_s).to eq(data[:limits][:limit])
  end
  it "Delete resource" do
    @br.delete_base_resource(@bp_id, @br.br_id)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response.first).to eq('BaseResource not found')
  end
end
