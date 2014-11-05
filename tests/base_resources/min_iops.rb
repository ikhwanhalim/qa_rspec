# Check Limits for guaranteed minIOPS
require './lib/onapp_base_resource'

describe "Check Limits for guaranteed minIOPS" do
########################################################################################################################
  before(:all) do
    # Get real BackupServerZone id
    @bp = OnappBilling.new
    @br = OnappBaseResource.new
    # Create BP before testing
    @bp.create_billing_plan({:label => 'TestBPForBaseResources'})
    @bp_id = @bp.bp_id
    # Return dsz id if data_store_type = "solidfire" otherwise nil
    @dsz_id = @br.dsz_solidfire?
    
  end

  after(:all) do
    @bp.delete_billing_plan(@bp_id)
  end

  if !@dsz_id #!@br.dsz_solidfire?
    it "Create 'min IOPS' limit for not SolidFire DataStore type" do
      data = {:resource_class => "Resource::SolidFire",
              :target_id => @br.get_zone_id(type=:store),
              :target_type => "Pack"
      }
      response = @br.create_base_resource(@bp_id, data)
      expect(response['errors']['base'].first).to eq("Target not found") # Correct message will be available after 3.5.3
    end
  else
  ########################################################################################################################
    it "Create 'min IOPS' limit for unexisted DataStore Zone id" do
      data = {:resource_class => "Resource::SolidFire",
              :target_id => 0,
              :target_type => "Pack"
      }
      response = @br.create_base_resource(@bp_id, data)
      expect(response['errors']['base'].first).to eq("Target not found")
    end
  ########################################################################################################################
    # Check 'Free' limits
    it "Create 'min IOPS' limit with negative 'Free' value" do
      data = {:resource_class => "Resource::SolidFire",
              :target_id => @dsz_id,
              :target_type => "Pack",
              :limits => {
                  :limit_free => "-2"
              }
      }
      response = @br.create_base_resource(@bp_id, data)
      expect(response['errors']['limit_free'].first).to eq("must be greater than or equal to 0")
    end

    it "Create 'min IOPS' limit with pozitive 'Free' value > 0" do
      data = {:resource_class => "Resource::SolidFire",
              :target_id => @dsz_id,
              :target_type => "Pack",
              :limits => {
                  :limit_free => "2"
              }
      }
      response = @br.create_base_resource(@bp_id, data)
      expect(response['base_resource']['limits']['limit_free']).to eq("#{data[:limits][:limit_free]} request")
    end

    it "Edit 'min IOPS' limit 'Free' value, set 0" do
      data = {:limits => {
                  :limit_free => "0"
              }
      }
      @br.edit_base_resource(@bp_id, @br.br_id, data)
      response = @br.get_base_resource(@bp_id, @br.br_id)
      expect(response['base_resource']['limits']['limit_free'].to_s).to eq(data[:limits][:limit_free])
    end

    it "Delete 'min IOPS' limit resource" do
      @br.delete_base_resource(@bp_id, @br.br_id)
      response = @br.get_base_resource(@bp_id, @br.br_id)
      expect(response['errors'].first).to eq('BaseResource not found')
    end
  ########################################################################################################################
    # Check 'Max' limits
    it "Create 'min IOPS' limit with negative 'Max' value" do
      data = {:resource_class => "Resource::SolidFire",
              :target_id => @dsz_id,
              :target_type => "Pack",
              :limits => {
                  :limit => "-2"
              }
      }
      response = @br.create_base_resource(@bp_id, data)
      expect(response['errors']['limit'].first).to eq("must be greater than or equal to 0")
    end

    it "Create 'min IOPS' limit with pozitive 'Max' value > 0" do
      data = {:resource_class => "Resource::SolidFire",
              :target_id => @dsz_id,
              :target_type => "Pack",
              :limits => {
                  :limit => "2"
              }
      }
      response = @br.create_base_resource(@bp_id, data)
      expect(response['base_resource']['limits']['limit']).to eq("#{data[:limits][:limit]} request")
    end

    it "Edit 'min IOPS' limit 'Max' value, set 0 (Unlimited)" do
      data = {:limits => {
                  :limit => "0"
              }
      }
      @br.edit_base_resource(@bp_id, @br.br_id, data)
      response = @br.get_base_resource(@bp_id, @br.br_id)
      expect(response['base_resource']['limits']['limit'].to_s).to eq(data[:limits][:limit])
    end

    it "Delete 'min IOPS' limit resource" do
      @br.delete_base_resource(@bp_id, @br.br_id)
      response = @br.get_base_resource(@bp_id, @br.br_id)
      expect(response['errors'].first).to eq('BaseResource not found')
    end
  ########################################################################################################################
    # Check 'Prices On'
    it "Create 'min IOPS' limit with negative 'Price On' value" do
      data = {:resource_class => "Resource::SolidFire",
              :target_id => @dsz_id,
              :target_type => "Pack",
              :prices => {
                  :price_on => "-2"
              }
      }
      response = @br.create_base_resource(@bp_id, data)
      expect(response['errors']['price_on'].first).to eq("must be greater than or equal to 0")
    end

    it "Create 'min IOPS' limit with pozitive 'Price On' value > 0" do
      data = {:resource_class => "Resource::SolidFire",
              :target_id => @dsz_id,
              :target_type => "Pack",
              :prices => {
                  :price_on => "2"
              }
      }
      response = @br.create_base_resource(@bp_id, data)
      expect(response['base_resource']['prices']['price_on']).to eq("$#{data[:prices][:price_on]}.00 per request /hr")
    end

    it "Edit 'min IOPS' limit 'Price On' value, set 0" do
      data = {:prices => {
          :price_on => 0
      }
      }
      @br.edit_base_resource(@bp_id, @br.br_id, data)
      response = @br.get_base_resource(@bp_id, @br.br_id)
      expect(response['base_resource']['prices']['price_on']).to eq(data[:prices][:price_on])
    end

    it "Delete 'min IOPS' limit resource" do
      @br.delete_base_resource(@bp_id, @br.br_id)
      response = @br.get_base_resource(@bp_id, @br.br_id)
      expect(response['errors'].first).to eq('BaseResource not found')
    end
  ########################################################################################################################
    # Check 'Prices Off'
    it "Create 'min IOPS' limit with negative 'Price Off' value" do
      data = {:resource_class => "Resource::SolidFire",
              :target_id => @dsz_id,
              :target_type => "Pack",
              :prices => {
                  :price_off => "-2"
              }
      }
      response = @br.create_base_resource(@bp_id, data)
      expect(response['errors']['price_off'].first).to eq("must be greater than or equal to 0")
    end

    it "Create 'min IOPS' limit with pozitive 'Price Off' value > 0" do
      data = {:resource_class => "Resource::SolidFire",
              :target_id => @dsz_id,
              :target_type => "Pack",
              :prices => {
                  :price_off => "2"
              }
      }
      response = @br.create_base_resource(@bp_id, data)
      expect(response['base_resource']['prices']['price_off']).to eq("$#{data[:prices][:price_off]}.00 per request /hr")
    end

    it "Edit 'min IOPS' limit 'Price Off' value, set 0" do
      data = {:prices => {
          :price_off => 0
      }
      }
      @br.edit_base_resource(@bp_id, @br.br_id, data)
      response = @br.get_base_resource(@bp_id, @br.br_id)
      expect(response['base_resource']['prices']['price_off']).to eq(data[:prices][:price_off])
    end

    it "Delete 'min IOPS' limit resource" do
      @br.delete_base_resource(@bp_id, @br.br_id)
      response = @br.get_base_resource(@bp_id, @br.br_id)
      expect(response['errors'].first).to eq('BaseResource not found')
    end
  end
end