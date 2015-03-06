class CreateReports < ActiveRecord::Migration
  def change
    create_table :reports do |t|
      t.text    :spec_files
      t.string  :template_name
      t.string  :virt
      t.integer :run_id
      t.string  :report_file
      t.string  :status, :default => "Ready"

      t.timestamps
    end
  end
end
