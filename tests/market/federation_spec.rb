require 'onapp_supplier'
require 'onapp_trader'
require 'virtual_machine/vm_base'


describe "Market" do
  before :all do
    @supplier = OnappSupplier.new
    @trader = OnappTrader.new
  end

###############################################
##Tests if zone has been published as private##
###############################################

  context "Zone has been published as private" do
    before :all do
      @supplier.add_to_federation(private: 1)
    end

    after :all do
      @supplier.remove_all_from_federation
    end

    let(:federation_id) { @supplier.published_zone['federation_id'] }

    describe "Supplier" do
      it "should be able generate tokens" do
        @supplier.generate_token(:receiver)
        token = @supplier.get_token('receiver')['token']
        expect(token).not_to be nil
      end
    end

    describe "Trader" do
      it "should not be able subscribe to private zone" do
        expect(@trader.subscribe(federation_id).keys.first).to eq 'errors'
      end

      it "should be able subscribe with token and zone should be able after unsubscribing" do
        @supplier.generate_token(:receiver)
        token = @supplier.get_token('receiver')['token']
        @trader.use_token(:sender, token['token'])
        @trader.wait_for_publishing(federation_id)
        @trader.subscribe(federation_id)
        expect(@trader.subscribed_zone).not_to be nil
        @trader.unsubscribe_all
        ids = @trader.all_unsubscribed.map {|z| z['federation_id']}
        expect(ids.include?(federation_id)).to be true
      end
    end
  end

############################
##Tests for published zone##
############################

  context "Zone has been published" do
    before :all do
      @supplier.add_to_federation(label: "Simple Zone Label")
      @trader.wait_for_publishing @supplier.published_zone['federation_id']
    end

    after :all do
      @supplier.remove_all_from_federation
    end

    let(:federation_id) { @supplier.published_zone['federation_id'] }

    describe "Supplier" do
      it "should be able add to federation" do
        expect(@supplier.published_zone['federation_enabled']).to be true
        expect(federation_id).to be_present
      end

      it "should not be able generate tokens if zone public" do
        expect(@supplier.generate_token(:receiver).keys.first).to eq 'error'
      end
    end

    describe "Trader" do
      it "should not be able subscribe to disabled zone" do
        @supplier.disable_zone
        expect(@trader.subscribe(federation_id).keys.first).to eq 'errors'
        @supplier.enable_zone
        @trader.wait_for_publishing federation_id
        federation_ids = @trader.all_unsubscribed.map {|z| z['federation_id']}
        expect(federation_ids).to include(federation_id)
      end

      it "should be able search zone by part of label" do
        federation_ids = @trader.search('zone').map {|z| z['federation_id']}
        expect(federation_ids).to include(federation_id)
      end

      it "should be able search zone by whole label" do
        federation_ids = @trader.search('simple zone label').map {|z| z['federation_id']}
        expect(federation_ids).to include(federation_id)
      end

      it "search zone by wrong label" do
        federation_ids = @trader.search('wrong label').map {|z| z['federation_id']}
        expect(federation_ids).not_to include(federation_id)
      end

      it "search zone by mix label parts" do
        federation_ids = @trader.search('label simple').map {|z| z['federation_id']}
        expect(federation_ids).to include(federation_id)
      end
    end
  end

#############################
##Tests for subscribed zone##
#############################

  context "Zone has been subscribed" do
    before :all do
      @supplier.add_to_federation
      @trader.wait_for_publishing @supplier.published_zone['federation_id']
      @trader.subscribe @supplier.published_zone['federation_id']
    end

    after :all do
      @trader.unsubscribe_all
      @supplier.remove_all_from_federation
    end

    let(:federation_id) { @trader.subscribed_zone['federation_id'] }

    describe "Supplier" do
      it "should not be able remove zone if trader has subscribed to it" do
        @supplier.disable_zone
        @supplier.remove_from_federation
        expect(@supplier.all_federated.any?).to be true
        @supplier.enable_zone
        expect(@supplier.published_zone['federation_enabled']).to be true
      end
    end

    describe "Trader" do
      it "zone should be present" do
        expect(@trader.subscribed_zone).to be_present
      end

      it "should be able subscribe to zone" do
        expect(federation_id).to eq @supplier.published_zone['federation_id']
      end

      it "should not be able subscribe to zone twice" do
        expect(@trader.subscribe(federation_id).keys.first).to eq 'errors'
      end

      it "should has virtual template group" do
        tg_labels = @trader.get_all('/template_store').map {|tg| tg['label']}
        expect(tg_labels).to include federation_id
      end

      it "should has virtual data store and data store zone" do
        dsz_labels = @trader.get_all('/settings/data_store_zones').map {|dsz| dsz['data_store_group']['label']}
        ds_labels = @trader.get_all('/settings/data_stores').map {|ds| ds['data_store']['label']}
        expect(dsz_labels).to include federation_id
        expect(ds_labels).to include federation_id
      end

      it "should has virtual network and network zone" do
        ntz_labels = @trader.get_all('/settings/network_zones').map {|ntz| ntz['network_group']['label']}
        nt_labels = @trader.get_all('/settings/networks').map {|nt| nt['network']['label']}
        expect(ntz_labels).to include federation_id
        expect(nt_labels).to include federation_id
      end

      it "should has virtual hypervisor" do
        hv_labels = @trader.get_all('/settings/hypervisors').map {|hv| hv['hypervisor']['label']}
        expect(hv_labels).to include federation_id
      end

      it "error should appeared if no enough resources on supplier" do
        @supplier.data_stores_detach
        error = @trader.create_vm(@supplier.template['label'], federation_id).to_s
        expect(error.include?("aren't enough resources")).to be true
        @supplier.data_stores_attach
      end
    end
  end
end
