class AddDataToTrackedSiteProductIndex < ActiveRecord::Migration[7.0]
  def change
    add_column :tracked_site_product_indices, :data, :json
  end
end
