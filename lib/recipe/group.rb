class Recipe::Group
  attr_reader :interface, :label, :id, :parent_id, :recipes

  def initialize(interface)
    @interface = interface
    @recipes = []
  end

  def create(**params)
    data = group_params.merge(params)
    json_response = interface.post(groups_route, recipe_group: data)
    attrs_update json_response
  end

  def groups_route
    '/recipe_groups'
  end

  def route
    "#{groups_route}/#{id}"
  end

  def attach_recipe(recipe_id: nil, **params)
    recipe = ::Recipe.new(interface)
    if recipe_id
      recipe.find(recipe_id)
    else
      recipe.create(params)
      recipe.add_step
    end
    relation = { recipe_group_relation: {recipe_id: recipe.id, recipe_group_id: id} }
    interface.post("#{route}/recipe_group_relations", relation)
    @recipes << recipe
  end

  def remove
    interface.delete route
  end

  def attrs_update(attrs=nil)
    attrs ||= interface.get(route)
    attrs.values.first.each { |k,v| instance_variable_set("@#{k}", v) }
    self
  end

  def group_params
    {
      label: "Group-#{SecureRandom.hex(4)}",
      parent_id: ''
    }
  end
end