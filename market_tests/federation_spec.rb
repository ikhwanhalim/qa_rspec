require 'onapp_supplier'
require 'onapp_trader'

describe "Supplier basic tests" do
  before :all do
    @supplier = OnappSupplier.new
    @trader = OnappTrader.new
    if @supplier.all_federated.empty?
      @supplier.add_to_federation
    else
      @supplier.published_zone = @supplier.all_federated.first
    end
  end

  after :all do
    @trader.unsubscribe_all
    @supplier.remove_all_from_federation
  end

  it "Add to federation" do
    @supplier.published_zone["federation_enabled"].should be_true
    @supplier.published_zone["federation_id"].should be_true
  end

  it "Trader should be able subscribe to zone" do
    @trader.subscribe(@supplier.published_zone["federation_id"])
    @trader.subscribed_zone.should be_true
    @trader.subscribed_zone['federation_id'].should eq @supplier.published_zone['federation_id']
  end
end
