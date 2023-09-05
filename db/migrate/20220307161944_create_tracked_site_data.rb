class CreateTrackedSiteData < ActiveRecord::Migration[5.2]
  def change
    create_table :tracked_site_data do |t|
      t.datetime :start_time
      t.datetime :end_time
      t.references :tracked_site, foreign_key: true
      t.json :data

      t.timestamps
    end
  end
end
