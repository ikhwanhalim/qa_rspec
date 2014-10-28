# Check Backup Server Zone limits
require './lib/onapp_base_resource'

describe "Check Backup Server Zone limits" do
########################################################################################################################
  before(:all) do
    # Get real BackupServerZone id
    @bp = OnappBilling.new
    @br = OnappBaseResource.new
    # Create BP before testing
    @bp.create_billing_plan({:label => 'TestBPForBaseResources'})
    @bp_id = @bp.bp_id
    @bsz_id = @br.get_zone_id(type = :backup)
  end

  after(:all) do
    @bp.delete_billing_plan(@bp_id)
  end
########################################################################################################################
  it "Create Backup Server Zone limit with unexisted backup server zone id" do
    data = {:resource_class => "Resource::BackupServerGroup",
            :target_id => 0,
            :target_type => "Pack"
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['errors']['base'].first).to eq("Target not found")
  end
########################################################################################################################
  # Check 'Backups' limits
########################################################################################################################
  # Check 'Free' limits
  it "Create 'Backups' limit with negative 'Free' value" do
    puts @bp_id
    data = {:resource_class => "Resource::BackupServerGroup",
            :target_id => @bsz_id,
            :target_type => "Pack",
            :limits => {
                :limit_backup_free => "-2"
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['errors']['limit_backup_free'].first).to eq("must be greater than or equal to 0")
  end

  it "Create 'Backups' limit with pozitive 'Free' value > 0" do
    puts @bp_id
    data = {:resource_class => "Resource::BackupServerGroup",
            :target_id => @bsz_id,
            :target_type => "Pack",
            :limits => {
                :limit_backup_free => "2"
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['base_resource']['limits']['limit_backup_free']).to eq(data[:limits][:limit_backup_free])
  end

  it "Edit 'Backups' limit 'Free' value, set 0" do
    puts @bp_id
    data = {:limits => {
                :limit_backup_free => 20
            }
    }
    @br.edit_base_resource(@bp_id, @br.br_id, data)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response['base_resource']['limits']['limit_backup_free']).to eq(data[:limits][:limit_backup_free])
  end

  it "Delete 'Backups' limit resource" do
    @br.delete_base_resource(@bp_id, @br.br_id)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response['errors'].first).to eq('BaseResource not found')
  end
########################################################################################################################
  # Check 'Max' limits
  it "Create 'Backups' limit with negative 'Max' value" do
    puts @bp_id
    data = {:resource_class => "Resource::BackupServerGroup",
            :target_id => @bsz_id,
            :target_type => "Pack",
            :limits => {
                :limit_backup => "-2"
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['errors']['limit_backup'].first).to eq("must be greater than or equal to 0")
  end

  it "Create 'Backups' limit with pozitive 'Max' value > 0" do
    puts @bp_id
    data = {:resource_class => "Resource::BackupServerGroup",
            :target_id => @bsz_id,
            :target_type => "Pack",
            :limits => {
                :limit_backup => "2"
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['base_resource']['limits']['limit_backup']).to eq(data[:limits][:limit_backup])
  end

  it "Edit 'Backups' limit 'Max' value, set 0 (Unlimited)" do
    puts @bp_id
    data = {:limits => {
        :limit_backup => 20
    }
    }
    @br.edit_base_resource(@bp_id, @br.br_id, data)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response['base_resource']['limits']['limit_backup']).to eq(data[:limits][:limit_backup])
  end

  it "Delete 'Backups' limit resource" do
    @br.delete_base_resource(@bp_id, @br.br_id)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response['errors'].first).to eq('BaseResource not found')
  end
########################################################################################################################
  # Check 'Prices'
  it "Create 'Backups' limit with negative 'Price' value" do
    puts @bp_id
    data = {:resource_class => "Resource::BackupServerGroup",
            :target_id => @bsz_id,
            :target_type => "Pack",
            :prices => {
                :price_backup => "-2"
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['errors']['price_backup'].first).to eq("must be greater than or equal to 0")
  end

  it "Create 'Backups' limit with pozitive 'Price' value > 0" do
    puts @bp_id
    data = {:resource_class => "Resource::BackupServerGroup",
            :target_id => @bsz_id,
            :target_type => "Pack",
            :prices => {
                :price_backup => "2"
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['base_resource']['prices']['price_backup']).to eq("$#{data[:prices][:price_backup]}.00 /hr")
  end

  it "Edit 'Backups' limi 'Price' value, set 0" do
    puts @bp_id
    data = {:prices => {
        :price_backup => 20
    }
    }
    @br.edit_base_resource(@bp_id, @br.br_id, data)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response['base_resource']['prices']['price_backup']).to eq(data[:prices][:price_backup])
  end

  it "Delete 'Backups' limit resource" do
    @br.delete_base_resource(@bp_id, @br.br_id)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response['errors'].first).to eq('BaseResource not found')
  end

########################################################################################################################
  # Check 'Backup Disk Size' limits
########################################################################################################################
  # Check 'Free' limits
  it "Create 'Backup Disk Size' limit with negative 'Free' value" do
    puts @bp_id
    data = {:resource_class => "Resource::BackupServerGroup",
            :target_id => @bsz_id,
            :target_type => "Pack",
            :limits => {
                :limit_backup_disk_size_free => "-2"
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['errors']['limit_backup_disk_size_free'].first).to eq("must be greater than or equal to 0")
  end

  it "Create 'Backup Disk Size' limit with pozitive 'Free' value > 0" do
    puts @bp_id
    data = {:resource_class => "Resource::BackupServerGroup",
            :target_id => @bsz_id,
            :target_type => "Pack",
            :limits => {
                :limit_backup_disk_size_free => "2"
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['base_resource']['limits']['limit_backup_disk_size_free']).to eq("#{data[:limits][:limit_backup_disk_size_free]} GB")
  end

  it "Edit 'Backup Disk Size' limit 'Free' value, set 0" do
    puts @bp_id
    data = {:limits => {
        :limit_backup_disk_size_free => 20
    }
    }
    @br.edit_base_resource(@bp_id, @br.br_id, data)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response['base_resource']['limits']['limit_backup_disk_size_free']).to eq(data[:limits][:limit_backup_disk_size_free])
  end

  it "Delete 'Backup Disk Size' limit resource" do
    @br.delete_base_resource(@bp_id, @br.br_id)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response['errors'].first).to eq('BaseResource not found')
  end
########################################################################################################################
  # Check 'Max' limits
  it "Create 'Backup Disk Size' limit with negative 'Max' value" do
    puts @bp_id
    data = {:resource_class => "Resource::BackupServerGroup",
            :target_id => @bsz_id,
            :target_type => "Pack",
            :limits => {
                :limit_backup_disk_size => "-2"
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['errors']['limit_backup_disk_size'].first).to eq("must be greater than or equal to 0")
  end

  it "Create 'Backup Disk Size' limit with pozitive 'Max' value > 0" do
    puts @bp_id
    data = {:resource_class => "Resource::BackupServerGroup",
            :target_id => @bsz_id,
            :target_type => "Pack",
            :limits => {
                :limit_backup_disk_size => "2"
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['base_resource']['limits']['limit_backup_disk_size']).to eq("#{data[:limits][:limit_backup_disk_size]} GB")
  end

  it "Edit 'Backup Disk Size' limit 'Max' value, set 0 (Unlimited)" do
    puts @bp_id
    data = {:limits => {
        :limit_backup_disk_size => 20
    }
    }
    @br.edit_base_resource(@bp_id, @br.br_id, data)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response['base_resource']['limits']['limit_backup_disk_size']).to eq(data[:limits][:limit_backup_disk_size])
  end

  it "Delete 'Backup Disk Size' limit resource" do
    @br.delete_base_resource(@bp_id, @br.br_id)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response['errors'].first).to eq('BaseResource not found')
  end
########################################################################################################################
  # Check 'Prices'
  it "Create 'Backup Disk Size' limit with negative 'Price' value" do
    puts @bp_id
    data = {:resource_class => "Resource::BackupServerGroup",
            :target_id => @bsz_id,
            :target_type => "Pack",
            :prices => {
                :price_backup_disk_size => "-2"
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['errors']['price_backup_disk_size'].first).to eq("must be greater than or equal to 0")
  end

  it "Create 'Backup Disk Size' limit with pozitive 'Price' value > 0" do
    puts @bp_id
    data = {:resource_class => "Resource::BackupServerGroup",
            :target_id => @bsz_id,
            :target_type => "Pack",
            :prices => {
                :price_backup_disk_size => "2"
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['base_resource']['prices']['price_backup_disk_size']).to eq("$#{data[:prices][:price_backup_disk_size]}.00 per GB /hr")
  end

  it "Edit 'Backup Disk Size' limit 'Price' value, set 0" do
    puts @bp_id
    data = {:prices => {
        :price_backup_disk_size => 20
    }
    }
    @br.edit_base_resource(@bp_id, @br.br_id, data)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response['base_resource']['prices']['price_backup_disk_size']).to eq(data[:prices][:price_backup_disk_size])
  end

  it "Delete 'Backup Disk Size' limit resource" do
    @br.delete_base_resource(@bp_id, @br.br_id)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response['errors'].first).to eq('BaseResource not found')
  end
########################################################################################################################
  # Check 'Templates' limits
########################################################################################################################
  # Check 'Free' limits
  it "Create 'Templates' limit with negative 'Free' value" do
    puts @bp_id
    data = {:resource_class => "Resource::BackupServerGroup",
            :target_id => @bsz_id,
            :target_type => "Pack",
            :limits => {
                :limit_template_free => "-2"
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['errors']['limit_template_free'].first).to eq("must be greater than or equal to 0")
  end

  it "Create 'Templates' limit with pozitive 'Free' value > 0" do
    puts @bp_id
    data = {:resource_class => "Resource::BackupServerGroup",
            :target_id => @bsz_id,
            :target_type => "Pack",
            :limits => {
                :limit_template_free => "2"
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['base_resource']['limits']['limit_template_free']).to eq(data[:limits][:limit_template_free])
  end

  it "Edit 'Templates' limit 'Free' value, set 0" do
    puts @bp_id
    data = {:limits => {
        :limit_template_free => 20
    }
    }
    @br.edit_base_resource(@bp_id, @br.br_id, data)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response['base_resource']['limits']['limit_template_free']).to eq(data[:limits][:limit_template_free])
  end

  it "Delete 'Templates' limit resource" do
    @br.delete_base_resource(@bp_id, @br.br_id)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response['errors'].first).to eq('BaseResource not found')
  end
########################################################################################################################
  # Check 'Max' limits
  it "Create 'Templates' limit with negative 'Max' value" do
    puts @bp_id
    data = {:resource_class => "Resource::BackupServerGroup",
            :target_id => @bsz_id,
            :target_type => "Pack",
            :limits => {
                :limit_template => "-2"
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['errors']['limit_template'].first).to eq("must be greater than or equal to 0")
  end

  it "Create 'Templates' limit with pozitive 'Max' value > 0" do
    puts @bp_id
    data = {:resource_class => "Resource::BackupServerGroup",
            :target_id => @bsz_id,
            :target_type => "Pack",
            :limits => {
                :limit_template => "2"
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['base_resource']['limits']['limit_template']).to eq(data[:limits][:limit_template])
  end

  it "Edit 'Templates' limit 'Max' value, set 0 (Unlimited)" do
    puts @bp_id
    data = {:limits => {
        :limit_template => 20
    }
    }
    @br.edit_base_resource(@bp_id, @br.br_id, data)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response['base_resource']['limits']['limit_template']).to eq(data[:limits][:limit_template])
  end

  it "Delete 'Templates' limit resource" do
    @br.delete_base_resource(@bp_id, @br.br_id)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response['errors'].first).to eq('BaseResource not found')
  end
########################################################################################################################
  # Check 'Prices'
  it "Create 'Templates' limit with negative 'Price' value" do
    puts @bp_id
    data = {:resource_class => "Resource::BackupServerGroup",
            :target_id => @bsz_id,
            :target_type => "Pack",
            :prices => {
                :price_template => "-2"
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['errors']['price_template'].first).to eq("must be greater than or equal to 0")
    
  end
  it "Create 'Templates' limit with pozitive 'Price' value > 0" do
    puts @bp_id
    data = {:resource_class => "Resource::BackupServerGroup",
            :target_id => @bsz_id,
            :target_type => "Pack",
            :prices => {
                :price_template => "2"
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['base_resource']['prices']['price_template']).to eq("$#{data[:prices][:price_template]}.00 /hr")
  end

  it "Edit 'Templates' limit 'Price' value, set 0" do
    puts @bp_id
    data = {:prices => {
        :price_template => 20
    }
    }
    @br.edit_base_resource(@bp_id, @br.br_id, data)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response['base_resource']['prices']['price_template']).to eq(data[:prices][:price_template])
  end

  it "Delete 'Templates' limit resource" do
    @br.delete_base_resource(@bp_id, @br.br_id)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response['errors'].first).to eq('BaseResource not found')
  end
########################################################################################################################
  # Check 'Template Disk Size' limits
########################################################################################################################
  # Check 'Free' limits
  it "Create 'Template Disk Size' limit with negative 'Free' value" do
    puts @bp_id
    data = {:resource_class => "Resource::BackupServerGroup",
            :target_id => @bsz_id,
            :target_type => "Pack",
            :limits => {
                :limit_template_disk_size_free => "-2"
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['errors']['limit_template_disk_size_free'].first).to eq("must be greater than or equal to 0")
  end

  it "Create 'Template Disk Size' limit with pozitive 'Free' value > 0" do
    puts @bp_id
    data = {:resource_class => "Resource::BackupServerGroup",
            :target_id => @bsz_id,
            :target_type => "Pack",
            :limits => {
                :limit_template_disk_size_free => "2"
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['base_resource']['limits']['limit_template_disk_size_free']).to eq("#{data[:limits][:limit_template_disk_size_free]} GB")
  end

  it "Edit 'Template Disk Size' limit 'Free' value, set 0" do
    puts @bp_id
    data = {:limits => {
        :limit_template_disk_size_free => 20
    }
    }
    @br.edit_base_resource(@bp_id, @br.br_id, data)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response['base_resource']['limits']['limit_template_disk_size_free']).to eq(data[:limits][:limit_template_disk_size_free])
  end

  it "Delete 'Template Disk Size' limit resource" do
    @br.delete_base_resource(@bp_id, @br.br_id)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response['errors'].first).to eq('BaseResource not found')
  end
########################################################################################################################
  # Check 'Max' limits
  it "Create 'Template Disk Size' limit with negative 'Max' value" do
    puts @bp_id
    data = {:resource_class => "Resource::BackupServerGroup",
            :target_id => @bsz_id,
            :target_type => "Pack",
            :limits => {
                :limit_template_disk_size => "-2"
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['errors']['limit_template_disk_size'].first).to eq("must be greater than or equal to 0")
  end

  it "Create 'Template Disk Size' limit with pozitive 'Max' value > 0" do
    puts @bp_id
    data = {:resource_class => "Resource::BackupServerGroup",
            :target_id => @bsz_id,
            :target_type => "Pack",
            :limits => {
                :limit_template_disk_size => "2"
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['base_resource']['limits']['limit_template_disk_size']).to eq("#{data[:limits][:limit_template_disk_size]} GB")
  end

  it "Edit 'Template Disk Size' limit 'Max' value, set 0 (Unlimited)" do
    puts @bp_id
    data = {:limits => {
        :limit_template_disk_size => 20
    }
    }
    @br.edit_base_resource(@bp_id, @br.br_id, data)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response['base_resource']['limits']['limit_template_disk_size']).to eq(data[:limits][:limit_template_disk_size])
  end

  it "Delete 'Template Disk Size' limit resource" do
    @br.delete_base_resource(@bp_id, @br.br_id)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response['errors'].first).to eq('BaseResource not found')
  end
########################################################################################################################
  # Check 'Prices'
  it "Create 'Template Disk Size' limit with negative 'Price' value" do
    puts @bp_id
    data = {:resource_class => "Resource::BackupServerGroup",
            :target_id => @bsz_id,
            :target_type => "Pack",
            :prices => {
                :price_template_disk_size => "-2"
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['errors']['price_template_disk_size'].first).to eq("must be greater than or equal to 0")
  end

  it "Create 'Template Disk Size' limit with pozitive 'Price' value > 0" do
    puts @bp_id
    data = {:resource_class => "Resource::BackupServerGroup",
            :target_id => @bsz_id,
            :target_type => "Pack",
            :prices => {
                :price_template_disk_size => "2"
            }
    }
    response = @br.create_base_resource(@bp_id, data)
    expect(response['base_resource']['prices']['price_template_disk_size']).to eq("$#{data[:prices][:price_template_disk_size]}.00 per GB /hr")
  end

  it "Edit 'Template Disk Size' limit 'Price' value, set 0" do
    puts @bp_id
    data = {:prices => {
        :price_template_disk_size => 20
        }
    }
    @br.edit_base_resource(@bp_id, @br.br_id, data)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response['base_resource']['prices']['price_template_disk_size']).to eq(data[:prices][:price_template_disk_size])
  end

  it "Delete 'Template Disk Size' limit resource" do
    @br.delete_base_resource(@bp_id, @br.br_id)
    response = @br.get_base_resource(@bp_id, @br.br_id)
    expect(response['errors'].first).to eq('BaseResource not found')
  end
########################################################################################################################
end
