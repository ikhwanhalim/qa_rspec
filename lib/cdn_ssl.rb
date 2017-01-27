require './spec/onapp/cdn/constants_cdn'

class CdnSsl
  include ConstantsCdn

  attr_reader :interface, :id

  def initialize(interface)
    @interface = interface
  end

  def attrs_update(attrs=nil)
    attrs ||= interface.get(route_edge_group)
    attrs.values.first.each { |k,v| instance_variable_set("@#{k}", v) }

    self
  end

  def create_ssl_certificate(**params)
    data = create_params.merge(**params)
    json_response = interface.post("#{route_ssl_certificates}", cdn_ssl_certificate: data)
    attrs_update json_response
  end

  def create_params
    {
       name: "ad-qa-ssl-#{generate_name(4)}",
       cert: SSL_CERT,
       key: SSL_KEY
    }
  end

  def edit(**params)
    interface.put(route_ssl_certificate, params)
  end

  def remove_ssl_certificate
    interface.delete route_ssl_certificate
  end

  def route_ssl_certificates
    '/cdn_ssl_certificates'
  end

  def route_ssl_certificate
    "#{route_ssl_certificates}/#{id}"
  end
end