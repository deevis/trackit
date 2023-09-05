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
  class Zillow < ::TrackedSite

    # To keep controller/view/form helpers from needing attention
    # https://stackoverflow.com/questions/4507149/best-practices-to-handle-routes-for-sti-subclasses-in-rails
    def self.model_name
      TrackedSite.model_name
    end

    def self.display_name; "Zillow"; end

    def get_data_html(tracked_site_datum)
      "#{tracked_site_datum.start_time.strftime("%m/%d/%Y")} : $#{tracked_site_datum.data['price']}"
    end

    def scrape_html(filepath=nil)
      doc = get_noko_doc(filepath)
      script = doc.css("script").select{|s| s.to_s.index("rentZestimate")}.first
      price = script.to_s.split(',\\"rentZestimate').first.split('zestimate\\":').last.to_i
      rent = script.to_s.split(',\\"rentZestimate\\":').last.split(',\\"currency\\":').first.to_i
      if price == 0
        # Fix - if there was no price found (house for sale, new home, ...)
        div = doc.css(".summary-container")
        if div
          price = div.css("span")[0].css("span").text.gsub("$","").gsub(",", "").to_i rescue 0
        end      
      end
      data = {price: price, rent: rent}.stringify_keys
      puts "    data: #{data}"
      scrape_image(doc) if self.image.blank?
      data
    end

    def scrape_image(doc=nil)
      doc ||= get_noko_doc
      images = doc.css(".media-stream-tile--prominent")
      url = images.css("img")[0]["src"]
      set_image_from_url(url)
    end

    def get_noko_doc(filepath=nil)
      if filepath.blank?
        filepath = "tracked_site_#{self.id || 'new'}.html"
        puts "Retrieving #{filepath} from #{self.url}"
        curl_command = <<~CURL
          curl -L '#{self.url}' \
          -H 'authority: www.zillow.com' \
          -H 'pragma: no-cache' \
          -H 'cache-control: no-cache' \
          -H 'sec-ch-ua: " Not A;Brand";v="99", "Chromium";v="98", "Google Chrome";v="98"' \
          -H 'sec-ch-ua-mobile: ?0' \
          -H 'sec-ch-ua-platform: "Windows"' \
          -H 'upgrade-insecure-requests: 1' \
          -H 'user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.102 Safari/537.36' \
          -H 'accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9' \
          -H 'sec-fetch-site: same-origin' \
          -H 'sec-fetch-mode: navigate' \
          -H 'sec-fetch-user: ?1' \
          -H 'sec-fetch-dest: document' \
          -H 'referer: https://www.zillow.com/' \
          -H 'accept-language: en-US,en;q=0.9,da;q=0.8' \
            --compressed > tracked_site_#{self.id}.html
        CURL
        puts curl_command
      end
      `#{curl_command}`
      puts "Nokogiri parsing #{filepath}"
      doc = Nokogiri::HTML(File.readlines(filepath).join("\n"))
    end
  end
end
