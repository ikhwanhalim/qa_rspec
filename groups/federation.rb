require 'federation_market'
require 'federation_supplier'
require 'federation_trader'

class Federation
  attr_reader :trader, :supplier, :market

  def initialize
    @trader = FederationTrader.new(self)
    @supplier = FederationSupplier.new(self)
    @market = FederationMarket.new(self)
  end

  def market
    @market.federation_id = supplier.published_zone.federation_id
    @market
  end
end