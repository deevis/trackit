class AddUnavailableToTrackedSites < ActiveRecord::Migration[7.0]
  def change
    add_column :tracked_sites, :unavailable, :boolean, default: false
  end
end
