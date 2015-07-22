class AddCronFields < ActiveRecord::Migration
  def change
    change_table :runs do |r|
      r.string :cron_period
      r.string :cron_status, default: 'Inactive'
    end
  end
end
