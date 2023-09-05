class AddPricesToTrackedSite < ActiveRecord::Migration[7.0]
  def change
    add_column :tracked_sites, :current_price, :decimal, precision: 10, scale: 2
    add_column :tracked_sites, :current_price_date, :datetime
    add_column :tracked_sites, :lowest_price, :decimal, precision: 10, scale: 2
    add_column :tracked_sites, :lowest_price_date, :datetime
    add_column :tracked_sites, :lowest_price_tracked_site_datum_id, :bigint
    add_column :tracked_sites, :highest_price, :decimal, precision: 10, scale: 2
    add_column :tracked_sites, :highest_price_date, :datetime
    add_column :tracked_sites, :highest_price_tracked_site_datum_id, :bigint

    add_foreign_key :tracked_sites, :tracked_site_data, column: :lowest_price_tracked_site_datum_id
    add_foreign_key :tracked_sites, :tracked_site_data, column: :highest_price_tracked_site_datum_id
  end
end

