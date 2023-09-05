class AddVariantChildFieldsToTrackedSites < ActiveRecord::Migration[7.0]
  def change
    add_column :tracked_sites, :tracked_site_parent_id, :bigint
    add_column :tracked_sites, :variant_definition, :json
    add_foreign_key :tracked_sites, :tracked_sites, column: :tracked_site_parent_id
  end
end
