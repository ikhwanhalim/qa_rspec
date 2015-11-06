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
    # Return dsz id by type otherwise nil
    @sf_dsz_id = @br.dsz_zone_id_by_type(type="solidfire")
    @lvm_dsz_id = @br.dsz_zone_id_by_type(type="lvm")
  end

  after(:all) do
    @bp.delete_billing_plan()
  end

  def ds_solidfire?
    raise 'There is no SolidFire datastore on this cloud.' if !@sf_dsz_id
  end

  it "Create 'min IOPS' limit for not SolidFire DataStore type" do
    data = {:resource_class => "Billing::Resource::SolidFire",
            :target_id => @lvm_dsz_id,
            :target_type => "Pack"
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['base'].first).to eq("Target not found")
  end
########################################################################################################################
  it "Create 'min IOPS' limit for unexisted DataStore Zone id" do
    data = {:resource_class => "Billing::Resource::SolidFire",
            :target_id => 0,
            :target_type => "Pack"
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['base'].first).to eq("Target not found")
  end
########################################################################################################################
  # Check 'Free' limits
  it "Create 'min IOPS' limit with negative 'Free' value" do
    ds_solidfire?
    data = {:resource_class => "Billing::Resource::SolidFire",
            :target_id => @sf_dsz_id,
            :target_type => "Pack",
            :limits => {
                :limit_free => -2
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['limit_free'].first).to eq("must be greater than or equal to 0")
  end

  it "Create 'min IOPS' limit with pozitive 'Free' value > 0" do
    ds_solidfire?
    data = {:resource_class => "Billing::Resource::SolidFire",
            :target_id => @sf_dsz_id,
            :target_type => "Pack",
            :limits => {
                :limit_free => 2
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['limits']['limit_free']).to eq("#{data[:limits][:limit_free]} request")
  end

  it "Edit 'min IOPS' limit 'Free' value, set 0" do
    ds_solidfire?
    data = {:limits => {
                :limit_free => 0
            }
    }
    @br.edit_base_resource(@bp_id, @br.br_id, data)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response['limits']['limit_free'].to_s).to eq(data[:limits][:limit_free])
  end

  it "Delete 'min IOPS' limit resource" do
    ds_solidfire?
    @br.delete_base_resource(@bp_id, @br.br_id)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response.first).to eq('Resource not found')
  end
########################################################################################################################
  # Check 'Max' limits
  it "Create 'min IOPS' limit with negative 'Max' value" do
    ds_solidfire?
    data = {:resource_class => "Billing::Resource::SolidFire",
            :target_id => @sf_dsz_id,
            :target_type => "Pack",
            :limits => {
                :limit => -2
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['limit'].first).to eq("must be greater than or equal to 0")
  end

  it "Create 'min IOPS' limit with pozitive 'Max' value > 0" do
    ds_solidfire?
    data = {:resource_class => "Billing::Resource::SolidFire",
            :target_id => @sf_dsz_id,
            :target_type => "Pack",
            :limits => {
                :limit => 2
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['limits']['limit']).to eq("#{data[:limits][:limit]} request")
  end

  it "Edit 'min IOPS' limit 'Max' value, set 0 (Unlimited)" do
    ds_solidfire?
    data = {:limits => {
                :limit => 0
            }
    }
    @br.edit_base_resource(@bp_id, @br.br_id, data)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response['limits']['limit'].to_s).to eq(data[:limits][:limit])
  end

  it "Delete 'min IOPS' limit resource" do
    ds_solidfire?
    @br.delete_base_resource(@bp_id, @br.br_id)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response.first).to eq('Resource not found')
  end
########################################################################################################################
  # Check 'Prices On'
  it "Create 'min IOPS' limit with negative 'Price On' value" do
    ds_solidfire?
    data = {:resource_class => "Billing::Resource::SolidFire",
            :target_id => @sf_dsz_id,
            :target_type => "Pack",
            :prices => {
                :price_on => -2
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['price_on'].first).to eq("must be greater than or equal to 0")
  end

  it "Create 'min IOPS' limit with pozitive 'Price On' value > 0" do
    ds_solidfire?
    data = {:resource_class => "Billing::Resource::SolidFire",
            :target_id => @sf_dsz_id,
            :target_type => "Pack",
            :prices => {
                :price_on => 2
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['prices']['price_on']).to eq(data[:prices][:price_on].to_f)
  end

  it "Edit 'min IOPS' limit 'Price On' value, set 0" do
    ds_solidfire?
    data = {:prices => {
        :price_on => 0
    }
    }
    @br.edit_base_resource(@bp_id, @br.br_id, data)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response['prices']['price_on']).to eq(data[:prices][:price_on])
  end

  it "Delete 'min IOPS' limit resource" do
    ds_solidfire?
    @br.delete_base_resource(@bp_id, @br.br_id)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response.first).to eq('Resource not found')
  end
########################################################################################################################
  # Check 'Prices Off'
  it "Create 'min IOPS' limit with negative 'Price Off' value" do
    ds_solidfire?
    data = {:resource_class => "Billing::Resource::SolidFire",
            :target_id => @sf_dsz_id,
            :target_type => "Pack",
            :prices => {
                :price_off => -2
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['price_off'].first).to eq("must be greater than or equal to 0")
  end

  it "Create 'min IOPS' limit with pozitive 'Price Off' value > 0" do
    ds_solidfire?
    data = {:resource_class => "Billing::Resource::SolidFire",
            :target_id => @sf_dsz_id,
            :target_type => "Pack",
            :prices => {
                :price_off => 2
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['prices']['price_off']).to eq(data[:prices][:price_off].to_f)
  end

  it "Edit 'min IOPS' limit 'Price Off' value, set 0" do
    ds_solidfire?
    data = {:prices => {
        :price_off => 0
    }
    }
    @br.edit_base_resource(@bp_id, @br.br_id, data)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response['prices']['price_off']).to eq(data[:prices][:price_off])
  end

  it "Delete 'min IOPS' limit resource" do
    ds_solidfire?
    @br.delete_base_resource(@bp_id, @br.br_id)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response.first).to eq('Resource not found')
  end
end