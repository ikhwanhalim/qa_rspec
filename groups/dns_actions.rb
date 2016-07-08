class DnsActions
  include ApiClient, Log

  attr_reader :dns

  def precondition
    @dns = Dns.new(self).create

    self
  end
end