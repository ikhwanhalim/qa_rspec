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
    @supplier.remove_all_from_federation
  end

  after :each do
    @trader.unsubscribe_all
  end

  it "Add to federation" do
    expect(@supplier.published_zone["federation_enabled"]).to be true
    expect(@supplier.published_zone["federation_id"]).to be_present
  end

  it "Trader should be able subscribe to zone" do
    @trader.subscribe(@supplier.published_zone["federation_id"])
    expect(@trader.subscribed_zone).to be_present
    expect(@trader.subscribed_zone['federation_id']).to eq @supplier.published_zone['federation_id']
  end

  it "Trader should not be able subscribe to disable zone" do
    @supplier.disable_zone @supplier.published_zone['id']
    expect(@trader.subscribe(@supplier.published_zone["federation_id"]).keys.first).to eq 'errors'
  end

  it "Trader should not be able subscribe to zone twice" do
    @trader.subscribe(@supplier.published_zone["federation_id"])
    expect(@trader.subscribe(@supplier.published_zone["federation_id"]).keys.first).to eq 'errors'
  end
end
