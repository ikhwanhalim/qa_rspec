require './spec/onapp/cdn/constants_cdn'

class EdgeGroup

  include ConstantsCdn

  attr_reader :interface, :id, :label

  def initialize(interface)
    @interface = interface
  end

  def attrs_update(attrs=nil)
    attrs ||= interface.get(route_edge_group)
    attrs.values.first.each { |k,v| instance_variable_set("@#{k}", v) }

    self
  end

  def create_edge_group(**params)
    data = create_params.merge(**params)
    json_response = interface.post("#{route_edge_groups}", edge_group: data)
    attrs_update json_response
  end

  def create_params
    {
       label: "ad-qa-eg-#{generate_name(4)}"
    }
  end

  def manipulation_with_locations(route, **params)
    interface.post(route, **params)
  end

  def edit(**params)
    interface.put(route_edge_group, params)
  end

  def remove_edge_group
    interface.delete route_edge_group
  end

  def route_edge_groups
    '/edge_groups'
  end

  def route_edge_group
    "#{route_edge_groups}/#{id}"
  end

  def route_available_eg
    '/cdn_resources/available_edge_groups'
  end

  def route_manipulation(action)
    "#{route_edge_group}/#{action}"
  end
end
