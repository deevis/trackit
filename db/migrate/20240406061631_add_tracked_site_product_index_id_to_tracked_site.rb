class AddTrackedSiteProductIndexIdToTrackedSite < ActiveRecord::Migration[7.0]
  def change
    # Add a new column as a foreign key reference
    add_reference :tracked_sites, :tracked_site_product_index, foreign_key: true
  end
end
