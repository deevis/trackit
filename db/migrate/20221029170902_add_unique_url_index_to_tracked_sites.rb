class AddUniqueUrlIndexToTrackedSites < ActiveRecord::Migration[7.0]
  def change
    add_index :tracked_sites, [:url], unique: true
  end
end
