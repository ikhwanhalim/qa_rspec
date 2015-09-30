require 'federation_market'
require 'federation_supplier'
require 'federation_trader'

class Federation
  attr_reader :trader, :supplier, :market

  def initialize
    @trader = FederationTrader.new
    @supplier = FederationSupplier.new
  end

  def market
    @market = FederationMarket.new(@supplier.published_zone.federation_id)
  end
end