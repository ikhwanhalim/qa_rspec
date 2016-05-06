class Recipe
  attr_reader :interface, :id, :label, :steps

  def initialize(interface)
    @interface = interface
    @steps = []
  end

  def create(**params)
    data = create_params.merge(params)
    json_response = interface.post('/recipes', recipe: data)
    attrs_update json_response
  end

  def edit(**params)
    interface.put(route, recipe: params)
    attrs_update
  end

  def remove
    interface.delete route
  end

  def find(recipe_id)
    attrs_update interface.get("/recipes/#{recipe_id}")
  end

  def create_params
    {
      label: "Recipe-#{SecureRandom.hex(4)}",
      compatible_with: 'unix'
    }
  end

  def add_step(**params)
    @steps << Recipe::Step.new(self).create(params)
  end

  def attrs_update(attrs=nil)
    attrs ||= interface.get(route)
    attrs.values.first.each { |k,v| instance_variable_set("@#{k}", v) }
    self
  end

  def route
    "/recipes/#{id}"
  end

  def remove
    interface.delete route
  end
end