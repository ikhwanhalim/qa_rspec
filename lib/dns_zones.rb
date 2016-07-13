class DnsZone
  attr_reader :interface, :records
  attr_reader :id, :name, :user_id, :cdn_reference, :errors

  def initialize(interface)
    @records = []
    @interface = interface
  end

  def create_dns_zone(**params)
    data = create_params.merge(params)
    json_response = interface.post("#{route_dns_zones}", dns_zone: data)
    attrs_update json_response
  end

  def create_params
    {
        name: "#{SecureRandom.hex}.com",
        #name: "#{(0...10).map { ('a'..'z').to_a[rand(5)] }.join}.com",
        auto_populate: '1'
    }
  end

  def attrs_update(attrs=nil)
    attrs ||= interface.get(route_specific_dns_zone)
    attrs.values.first.each { |k,v| instance_variable_set("@#{k}", v) }

    self
  end

  def route_dns_zone
    "/dns_zones/#{id}"
  end

  def route_dns_zones
    "/dns_zones"
  end

  def route_edit_dns_zone
    "/dns_zones/#{id}/records"
  end

  def generate_ipv4
    IPAddr.new(rand(2**32),Socket::AF_INET).to_s
  end

  def generate_ipv6
    IPAddr.new(rand(2**128),Socket::AF_INET6).to_s
  end

  def generate_number
    SecureRandom.random_number(2).to_s
  end

  def create_dns_record(**params)
    record = DnsRecord.new(self).create_record(params)
    @records << record
    record
  end

  def remove_dns_zone
    interface.delete route_dns_zone
  end

  def response_handler(response)
    @errors = response['errors']
    dns_incorrect_name = if response['name']
                           response['name']
                         elsif !@errors
                           get(id)['name']
                         end
    return Log.warn(@errors) if @errors
    dns_incorrect_name.each { |k, v| instance_variable_set("@#{k}", v)}
  end
end