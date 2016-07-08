class Dns
  attr_reader :interface, :id, :name

  def initialize(interface)
    @interface = interface
  end

  def create(**params)
    data = create_params.merge(params)
    json_response = interface.post('/dns_zones', dns_zone: data)
    attrs_update json_response
  end

  def create_params
    {
        name: "unix.com",
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
end