class AddTypeToTrackedSite < ActiveRecord::Migration[5.2]
  def change
    add_column :tracked_sites, :type, :string, limit: 64
  end
end
