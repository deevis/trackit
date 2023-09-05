class CreateTrackedSites < ActiveRecord::Migration[5.2]
  def change
    create_table :tracked_sites do |t|
      t.string :name
      t.string :url
      t.string :category
      t.string :sub_category

      t.timestamps
    end
  end
end
