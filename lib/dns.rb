class Dns
  attr_reader :interface, :id, :name, :user_id, :cdn_reference

  def initialize(interface)
    @interface = interface
  end

  def create(**params)
    data = create_params.merge(params)
    json_response = interface.post('/dns_zones', dns_zone: data)
    attrs_update json_response
  end

  # def random_label(length = 8)
  #   chars = ('a'..'z').to_a + ('0'..'9').to_a
  #   length.times.map { chars.sample }.join
  # end
  #
  # def random_domain_name(length = 8, domain = 'com')
  #   "#{random_label(length)}.#{domain}"
  # end

  def create_params
    {
        name: "#{SecureRandom.hex}.com",
        #name: "#{(0...10).map { ('a'..'z').to_a[rand(5)] }.join}.com",
        #name: "#{random_domain_name(6,'com')}",
        auto_populate: '1'
    }
  end

  def attrs_update(attrs=nil)
    attrs ||= interface.get(route)
    attrs.values.first.each { |k,v| instance_variable_set("@#{k}", v) }
    self
  end
  def route
    "/dns_zones/#{id}"
  end
  def route_edit
    "/dns_zones/#{id}/records"
  end

  def create_dns_record(**params)
    data_dns_record = create_params_dns_record.merge(params)
    json_response_dns_record = interface.post('/dns_zones/#{id}/records', dns_zone: data_dns_record)
    attrs_update json_response_dns_record
  end

  def create_params_dns_record
    { dns_record: {
        name: "test_com",
        ttl: "1",
        type: "A",
        ip: "127.0.0.1"
    }
    }
    end

  def remove
    interface.delete route
  end
end