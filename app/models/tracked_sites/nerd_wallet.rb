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
#
module TrackedSites
  class NerdWallet < ::TrackedSite

    # To keep controller/view/form helpers from needing attention
    # https://stackoverflow.com/questions/4507149/best-practices-to-handle-routes-for-sti-subclasses-in-rails
    def self.model_name
      TrackedSite.model_name
    end

    def self.display_name; "Mortgage Rates"; end

    def get_pricing_unit; "%"; end

    def get_default_variant;  ["30-year fixed-rate", "interest_rate"]; end

    # Returns an array of arrays like:
    #   [["[Premium]Gold Products 1 OZ - US Eagle", "Singles"]]
    def get_pricing_variants
      tracked_site_data.last.data.map do |item|
        [item['product']].product(item.except('product').keys)
      end.flatten(1)
    end

    # price should always return a hash with :price and :regular_price keys
    def get_price_for(tsd, variant)
      variant ||= get_default_variant
      price = tsd.data.detect{|row| row["product"] == variant[0]}[variant[1]] rescue -1
      price # {price: price, regular_price: nil}
    end


    def get_data_html(tracked_site_datum)
      return "N/A" if tracked_site_datum&.data.blank?
      thirty_year = tracked_site_datum.data.detect{|row| row["product"] == "30-year fixed-rate"}
      "#{tracked_site_datum.start_time.strftime("%m/%d/%Y")} : 30 year fixed: #{thirty_year['interest_rate']}"
    end

    def scrape_html(filepath=nil)
      if filepath.blank?
        filepath = "tracked_site_#{self.id}.html"
        puts "Retrieving #{filepath} from #{self.url}"

        curl_command = <<~CURL
          curl '#{self.url}' > #{filepath}
        CURL
        puts "=" * 50
        puts curl_command
        puts "=" * 50
        `#{curl_command}`
      end
      puts "Nokogiri parsing #{filepath}"
      doc = Nokogiri::HTML(File.readlines(filepath).join("\n"))
      div = doc.css("#rate-trends")
      rows = div.css("table > tbody > tr")
      data = rows.map{|r| {
        "product" => r.css("th").text, 
        "interest_rate" => r.css("td")[0].text.gsub(/[^\d\.]/, '').to_f, 
        "apr" => r.css("td")[1].text.gsub(/[^\d\.]/, '').to_f }
      }

      puts "    data: #{data}"
      data
    end

  end
end


