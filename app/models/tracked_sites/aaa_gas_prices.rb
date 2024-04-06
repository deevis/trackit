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
  class AaaGasPrices < ::TrackedSite

    # To keep controller/view/form helpers from needing attention
    # https://stackoverflow.com/questions/4507149/best-practices-to-handle-routes-for-sti-subclasses-in-rails
    def self.model_name
      TrackedSite.model_name
    end

    def self.display_name; "AAA Gas Prices"; end

    # Returns an array of arrays like:
    #   [["[Premium]Gold Products 1 OZ - US Eagle", "Singles"]]
    def get_pricing_variants
      tracked_site_data.last.data.map do |item|
        [item['state']].product(item.except('state').keys)
      end.flatten(1)
    end

    def get_default_variant; ["Utah", "regular"]; end

    # price should always return a hash with :price and :regular_price keys
    def get_price_for(tsd, variant=nil)
      variant ||= get_default_variant
      price = tsd.data.detect{|row| row["state"] == variant[0]}[variant[1]] rescue -1
      price # {price: price, regular_price: nil}
    end

    def get_data_html(tracked_site_datum)
       utah_price = get_price_for(tracked_site_datum, ["Utah", "regular"])
       tn_price = get_price_for(tracked_site_datum, ["Tennessee", "regular"])
       "#{tracked_site_datum.start_time.strftime("%m/%d/%Y")}: UT $#{utah_price}  TN $#{tn_price}"
    end

    def scrape_html(filepath=nil)
      doc = super(filepath)
      table = doc.css("table.sortable-table")
      data = table.css("tr").map do |r|
        cols = r.css("td")
        next if cols.length < 1
        { 
          state: cols[0].css("a").text.squish, 
          regular: cols[1].text.squish.gsub("$","").to_f, 
          mid_grade: cols[2].text.squish.gsub("$","").to_f, 
          premium: cols[3].text.squish.gsub("$","").to_f, 
          diesel: cols[4].text.squish.gsub("$","").to_f
        }.stringify_keys
      end.compact
      data.sort!{|a,b| a['state'] <=> b['state']}
      data      
    end
    
  end

end
