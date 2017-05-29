class DnsRecord

  attr_reader :interface, :dns_zone
  attr_reader :id

  def initialize(dns_zone)
    @interface = dns_zone.interface
    @dns_zone = dns_zone
  end

  def create_record(**params)
    data = create_params_dns_record.merge(params)
    json_response = interface.post(route_add_dns_record, dns_record: data)
    attrs_update json_response
  end

  def create_params_dns_record
    {
       ttl: generate_number,
       name: Faker::Internet.domain_word
    }
  end

  def generate_number
    Faker::Number.number(3)
  end

  def get
    json_response  = interface.get(route_to_specific_dns_record)
    attrs_update json_response
  end

  def edit(**params)
    interface.put(route_to_specific_dns_record, params)
  end

  def delete
    interface.delete(route_to_specific_dns_record)
  end

  def attrs_update(attrs=nil)
    attrs ||= interface.get(route_add_dns_record)
    attrs.values.first.each { |k,v| instance_variable_set("@#{k}", v) }

    self
  end

  def route_add_dns_record
    "/dns_zones/#{dns_zone.id}/records"
  end

  def route_to_specific_dns_record
    "/dns_zones/#{dns_zone.id}/records/#{id}"
  end

  def remove_dns_record
    interface.delete route_to_specific_dns_record
  end
end