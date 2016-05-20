class Recipe::Step
  attr_reader :interface, :recipe, :id, :script, :number

  def initialize(recipe)
    @interface = recipe.interface
    @recipe = recipe
  end

  def create(**params)
    data = step_params.merge(params)
    json_response = interface.post(steps_route, recipe_step: data)
    attrs_update json_response
  end

  def steps_route
    "#{recipe.route}/recipe_steps"
  end

  def route
    "#{steps_route}/#{id}"
  end

  def attrs_update(attrs=nil)
    attrs ||= interface.get(route)
    attrs.values.first.each { |k,v| instance_variable_set("@#{k}", v) }
    self
  end

  def remove
    interface.delete route
  end

  def step_params
    {
      script: SshCommands::OnVirtualServer.recipe_script(recipe.label),
      result_source: 'exit_code',
      pass_values: 0,
      pass_anything_else: 0,
      on_success: 'proceed',
      success_goto_step: '',
      fail_anything_else: 1,
      fail_values: '',
      on_failure: 'proceed',
      failure_goto_step: ''
    }
  end
end