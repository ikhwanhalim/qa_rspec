require 'onapp_supplier'

describe "Supplier basic tests" do
  before :all do
    @supplier = OnappSupplier.new
  end

  after :all do
    @supplier.remove_from_federation if @supplier
  end

  it "Add to federation" do
    @supplier.add_to_federation
    expect(@supplier.federation_id.empty?).to be_false
  end
end
