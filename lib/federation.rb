require 'federation_market'
require 'federation_supplier'
require 'federation_trader'

class Federation
  attr_reader :trader, :supplier, :market

  def initialize
    @trader = FederationTrader.instance
    @supplier = FederationSupplier.instance
    @market = FederationMarket.instance
  end

  def market
    @market.instance_variable_set(:@federation_id, @supplier.published_zone.federation_id)
    @market
  end
end