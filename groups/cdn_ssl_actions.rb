class CdnSslActions
  include ApiClient, Log

  attr_reader :ssl_cert

  def precondition
    @ssl_cert = CdnSsl.new(self).create_ssl_certificate

    self
  end
end
