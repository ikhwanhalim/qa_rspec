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
      def zone_search(action)
        5.times do
          zone = @trader.all_unsubscribed.select { |z| z['federation_id'] == federation_id }.first
          if action == :empty
            return zone unless zone
          elsif action == :any
            return zone if zone
          end
          sleep 1
        end
        false
      end

      it "should be able generate tokens" do
        @supplier.generate_token(:receiver)
        token = @supplier.get_token('receiver')['token']
        expect(token).not_to be nil
      end

      it 'private zone should not be visible for trader' do
        expect(zone_search(:empty)).to be_nil
      end

      it 'sould be able switch zone to public' do
        @supplier.make_public
        expect(zone_search(:any)['federation_id']).to eq federation_id
        @supplier.make_private
        expect(zone_search(:empty)).to be_nil
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
        federation_ids = @trader.search('wrong data').map {|z| z['federation_id']}
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

    after do
      expect(@trader.conn.page.code).to_not eq '500'
      expect(@supplier.conn.page.code).to_not eq '500'
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

      it "should be able create announcement" do
        id = @supplier.generate_announcement['announcement']['id']
        announcement = @supplier.wait_announcement_id(id)
        expect(announcement['announcement']['federation_id']).to include federation_id
      end

      it "should be able remove announcement" do
        id = @supplier.generate_announcement['announcement']['id']
        market_id = @supplier.wait_announcement_id(id)['announcement']['federation_id']
        announcement = @trader.find_announcement(market_id)
        expect(@trader.all_announcements).to include announcement
        @supplier.remove_announcement(id)
        expect(@trader.announcement_removed?(announcement)).to be true
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
        @trader.subscribe(federation_id)
        expect(@trader.conn.page.code).to eq "422"
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
        expect(@supplier.data_stores_attach).to be true
      end

      it 'should not be able remove federated template' do
        template = @trader.find_template(@supplier.template['label'])
        @trader.delete("/templates/#{template['id']}")
        expect(@trader.conn.page.code).to eq "422"
      end

      it 'should not be able remove federated template from template group' do
        err = @trader.delete("/settings/image_template_groups/%s/relation_group_templates/%s" %
                             [@trader.template_store['id'],
                             @trader.template_store['relations'].first['id']]
        )
        expect(@trader.conn.page.code).to eq "422"
        expect(err.to_s).to include "can't be added or deleted"
      end

      it 'should be able edit annoucement' do
        id = @supplier.generate_announcement['announcement']['id']
        market_id = @supplier.wait_announcement_id(id)['announcement']['federation_id']
        announcement_id = @trader.find_announcement(market_id)['announcement']['id']
        @trader.edit_announcement(announcement_id, 'modified')
        expect(@trader.find_announcement(market_id)['announcement']['text']).to eq 'modified'
      end
    end
  end
end
