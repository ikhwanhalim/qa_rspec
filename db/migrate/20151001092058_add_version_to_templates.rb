class AddVersionToTemplates < ActiveRecord::Migration
  def change
    add_column :templates, :version, :string
  end
end
