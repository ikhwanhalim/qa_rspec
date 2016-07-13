class DnsZoneActions
  include ApiClient, Log

  attr_reader :dns_zone

  def precondition
    @dns_zone = DnsZone.new(self).create_dns_zone

    self
  end
end