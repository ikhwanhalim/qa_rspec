class CreateRuns < ActiveRecord::Migration
  def change
    create_table :runs do |t|
      t.string    :title
      t.text      :files
      t.text      :templates
      t.text      :virt
      t.integer   :threads
      t.string    :server

      t.timestamps
    end
  end
end
