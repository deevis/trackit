# == Schema Information
#
# Table name: tracked_sites
#
#  id                                  :bigint           not null, primary key
#  name                                :string(255)
#  url                                 :string(255)
#  category                            :string(255)
#  sub_category                        :string(255)
#  created_at                          :datetime         not null
#  updated_at                          :datetime         not null
#  type                                :string(64)
#  current_price                       :decimal(10, 2)
#  current_price_date                  :datetime
#  lowest_price                        :decimal(10, 2)
#  lowest_price_date                   :datetime
#  lowest_price_tracked_site_datum_id  :bigint
#  highest_price                       :decimal(10, 2)
#  highest_price_date                  :datetime
#  highest_price_tracked_site_datum_id :bigint
#  unavailable                         :boolean          default(FALSE)
#  tracked_site_parent_id              :bigint
#  variant_definition                  :text(4294967295)
#  tracked_site_product_index_id       :bigint
#
module TrackedSites
  class MonarchCoin < ::TrackedSite

    # To keep controller/view/form helpers from needing attention
    # https://stackoverflow.com/questions/4507149/best-practices-to-handle-routes-for-sti-subclasses-in-rails
    def self.model_name
      TrackedSite.model_name
    end

    def self.display_name; "Monarch Coin"; end

    def get_default_variant;  ["[Premium]Silver Products - US Eagle", "Singles"]; end
    
    # Returns an array of arrays like:
    #   [["[Premium]Gold Products 1 OZ - US Eagle", "Singles"]]
    def get_pricing_variants
      tracked_site_data.last.data.map do |item|
        [item['Product']].product(item.except('Product').keys)
      end.flatten(1)
    end

    # price should always return a hash with :price and :regular_price keys
    def get_price_for(tsd, variant=variant_definition)
      variant ||= get_default_variant
      price = tsd.data.detect{|row| row["Product"] == variant[0]}[variant[1]] rescue -1
      price # {price: price, regular_price: nil}
    end

    def get_data_html(tracked_site_datum)
       silver_eagle_price = get_price_for(tracked_site_datum, ["[Premium]Silver Products - US Eagle", "Singles"])
       gold_eagle_price =  get_price_for(tracked_site_datum, ["[Premium]Gold Products 1 OZ - US Eagle", "Singles"])
       
       "#{tracked_site_datum.start_time.strftime("%m/%d/%Y")}: Silver $#{silver_eagle_price}  Gold $#{gold_eagle_price}"
    end

    def scrape_html(filepath=nil)
      doc = super(filepath)
      tables = doc.css("table.tableizer-table")
      silver_price_data = get_monarch_table_data(tables, "Silver Prod’s", 'Price')
      gold_price_data = get_monarch_table_data(tables, "Gold Products", 'Price')

      silver_premium_data = get_monarch_table_data(tables, "Silver Products", 'Premium')
      gold_premium_data = get_monarch_table_data(tables, "Gold Products 1 OZ", 'Premium')
      silver_price_data + gold_price_data + silver_premium_data + gold_premium_data
    end

    def get_monarch_table_data(tables, table_name, data_type)
      data = tables.detect do |t|
        rows = t.css("tbody > tr")
        th = rows[0].css("th")&.first
        th.present? && th.text == table_name
      end
      headers = nil
      results = data.css("tbody > tr").map do |r|
        headers ||= r.css("th").map{|th| th.text.squish}
        cols = r.css("td")
        next if cols.blank?
        Hash[cols.each_with_index.map do |td, idx|
          if idx == 0
            ["Product", "[#{data_type}]#{headers[idx]} - #{td.text.squish}"]
          else
            [headers[idx], td.text.squish.to_f]
          end
        end]
      end.compact
      results

    end


  end
end
