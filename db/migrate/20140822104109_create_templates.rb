class CreateTemplates < ActiveRecord::Migration
  def change
    create_table :templates do |t|
      t.string :label
      t.string :manager_id
      t.string :virtualization
      t.timestamps
    end
  end
end
