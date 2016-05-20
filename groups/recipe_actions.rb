class RecipeActions
  include ApiClient, Log

  attr_reader :recipe, :recipe_group

  def precondition
    @recipe = Recipe.new(self).create
    @recipe_group = Recipe::Group.new(self).create
    recipe_group.attach_recipe(recipe_id: recipe.id)

    self
  end
end