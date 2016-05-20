require 'spec_helper'
require './groups/recipe_actions'

describe 'Recipe' do
  before(:all) do
    @ra = RecipeActions.new.precondition
  end

  after(:all) do
    @ra.recipe.remove
    @ra.recipe_group.remove
  end

  let(:recipe) { @ra.recipe }
  let!(:label)  { @ra.recipe.label }

  it 'should be created' do
    @ra.get(recipe.route)
    expect(@ra.conn.page.code).to eq '200'
  end

  it 'should be edited' do
    recipe.edit(label: "Recipe-#{SecureRandom.hex(4)}")
    expect(label).not_to eq recipe.label
  end

  it 'ability remove label should be blocked' do
    recipe.edit(label: nil)
    expect(label).to eq recipe.label
  end

  it 'add step' do
    recipe.add_step
    expect(recipe.steps).not_to be_empty
  end

  describe 'Group' do
    let(:recipe_group) { @ra.recipe_group }

    it 'should be created' do
      @ra.get(recipe_group.route)
      expect(@ra.conn.page.code).to eq '200'
    end

    it 'recipe should be attached' do
      @ra.get("#{recipe_group}/recipe_group_relations").not_to be_empty
    end
  end
end