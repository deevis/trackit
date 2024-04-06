class CreateTrackedSiteProductIndices < ActiveRecord::Migration[7.0]
  def change
    create_table :tracked_site_product_indices do |t|
      t.string :tracked_site_class
      t.string :product_index_url
      t.string :category
      t.string :sub_category

      t.timestamps
    end
  end
end
