require 'federation'
require 'virtual_machine/vm_base'

describe "Market" do
  before :all do
    @federation = Federation.new
  end

  let(:federation) { @federation }
  let(:supplier) { @federation.supplier }
  let(:trader) { @federation.trader }

  context "Zone has been published as private" do
    before :all do
      @federation.supplier.add_to_federation(private: 1)
      @federation.market.set_preflight
    end

    after :all do
      @federation.supplier.remove_from_federation
    end

    let(:federation_id) { supplier.published_zone.federation_id }

    describe "Supplier" do
      it "should be able generate tokens" do
        supplier.generate_token(:receiver)
        token = supplier.get_token('receiver').token
        expect(token).not_to be nil
      end

      it 'private zone should not be visible for trader' do
        expect(trader.zone_disappeared?(federation_id)).to be true
      end

      it 'sould be able switch zone to public' do
        supplier.make_public
        expect(trader.zone_appeared?(federation_id)).to be true
        supplier.make_private
        expect(trader.zone_disappeared?(federation_id)).to be true
      end
    end

    describe "Trader" do
      it "should not be able subscribe to private zone" do
        trader.subscribe(federation_id)
        expect(trader.conn.page.code).to eq '422'
      end

      it "should be able subscribe with token and zone should be able after unsubscribing" do
        supplier.generate_token(:receiver)
        token = supplier.get_token('receiver').token
        trader.use_token(:sender, token.token)
        trader.wait_for_publishing(federation_id)
        trader.subscribe(federation_id)
        expect(trader.subscribed_zone).not_to be nil
        trader.unsubscribe_all
        ids = trader.all_unsubscribed.map {|z| z.federation_id}
        expect(ids.include?(federation_id)).to be true
      end
    end
  end

  context "Zone has been published as public" do
    before :all do
      @federation.supplier.add_to_federation(label: "Simple Zone Label")
      @federation.market.set_preflight
      @federation.trader.wait_for_publishing(@federation.market.federation_id)
    end

    after :all do
      @federation.supplier.remove_from_federation
    end

    let(:federation_id) { supplier.published_zone.federation_id }

    describe "Supplier" do
      it "should be able add to federation" do
        expect(supplier.published_zone.federation_enabled).to be true
        expect(federation_id).to be_present
      end

      it "should not be able generate tokens if zone public" do
        supplier.generate_token(:receiver)
        expect(supplier.conn.page.code).to eq '403'
      end
    end

    describe "Trader" do
      describe "preflight process" do
        before do
          @federation.market.set_preflight
        end

        it 'should be not passed' do
          @federation.market.set_preflight(status = true)
          expect(trader.zone_disappeared?(federation_id)).to be true
        end

        it 'should be passed' do
          expect(trader.zone_appeared?(federation_id)).to be true
        end
      end

      it "should not be able subscribe to disabled zone" do
        supplier.disable_zone
        trader.subscribe(federation_id)
        expect(trader.conn.page.code).to eq '422'
        supplier.enable_zone
        trader.wait_for_publishing federation_id
        federation_ids = trader.all_unsubscribed.map &:federation_id
        expect(federation_ids).to include(federation_id)
      end

      it "should be able search zone by part of label" do
        federation_ids = trader.search('zone').map &:federation_id
        expect(federation_ids).to include(federation_id)
      end

      it "should be able search zone by whole label" do
        federation_ids = trader.search('simple zone label').map &:federation_id
        expect(federation_ids).to include(federation_id)
      end

      it "search zone by wrong label" do
        federation_ids = trader.search('wrong data').map &:federation_id
        expect(federation_ids).not_to include(federation_id)
      end

      it "search zone by mix label parts" do
        federation_ids = trader.search('label simple').map &:federation_id
        expect(federation_ids).to include(federation_id)
      end
    end
  end
end
