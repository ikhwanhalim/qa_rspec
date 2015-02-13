require 'onapp_supplier'
require 'onapp_trader'
require 'virtual_machine/vm_base'


describe "Market" do
  before :all do
    @supplier = OnappSupplier.new
    @trader = OnappTrader.new
    @supplier.add_to_federation
    @federation_id = @supplier.published_zone['federation_id']
    @trader.subscribe(@federation_id)
  end

  after :all do
    @trader.unsubscribe_all
    @supplier.remove_all_from_federation
  end

  describe "Supplier" do
    it "should be able add to federation" do
      expect(@supplier.published_zone['federation_enabled']).to be true
      expect(@federation_id).to be_present
    end

    it "should not be able remove zone if trader has subscribed to it" do
      @supplier.disable_zone
      @supplier.remove_from_federation
      expect(@supplier.all_federated.any?).to be true
      @supplier.enable_zone
    end
  end

  describe "Trader" do
    it "should be able subscribe to zone" do
      expect(@trader.subscribed_zone).to be_present
      expect(@trader.subscribed_zone['federation_id']).to eq @federation_id
    end

    it "should not be able subscribe to disabled zone" do
      @trader.unsubscribe_all
      @supplier.disable_zone
      expect(@trader.subscribe(@federation_id).keys.first).to eq 'errors'
      @supplier.enable_zone
      @trader.subscribe(@federation_id)
      expect(@trader.subscribed_zone['federation_id']).to eq @federation_id
    end

    it "should not be able subscribe to zone twice" do
      expect(@trader.subscribe(@federation_id).keys.first).to eq 'errors'
    end

    it "should has virtual template group" do
      tg_labels = @trader.get_all('/template_store').map {|tg| tg['label']}
      expect(tg_labels).to include @federation_id
    end

    it "should has virtual data store and data store zone" do
      dsz_labels = @trader.get_all('/settings/data_store_zones').map {|dsz| dsz['data_store_group']['label']}
      ds_labels = @trader.get_all('/settings/data_stores').map {|ds| ds['data_store']['label']}
      expect(dsz_labels).to include @federation_id
      expect(ds_labels).to include @federation_id
    end

    it "should has virtual network and network zone" do
      ntz_labels = @trader.get_all('/settings/network_zones').map {|ntz| ntz['network_group']['label']}
      nt_labels = @trader.get_all('/settings/networks').map {|nt| nt['network']['label']}
      expect(ntz_labels).to include @federation_id
      expect(nt_labels).to include @federation_id
    end

    it "should has virtual virtual hypervisor" do
      hv_labels = @trader.get_all('/settings/hypervisors').map {|hv| hv['hypervisor']['label']}
      expect(hv_labels).to include @federation_id
    end
  end

  describe "Federation Virtual Machine" do
    before :all do
      template_label = @supplier.template['label']
      hash = @trader.building_resources(template_label, @federation_id)
      @vm = @trader.create(nil,nil,hash)
      expect(@vm.is_created?).to be true
    end

    after :all do
      @trader.destroy
      @trader.wait_for_destroy
    end

    it "should pinged after booting" do
      expect(@vm.pinged?).to be true
    end
  end
end
