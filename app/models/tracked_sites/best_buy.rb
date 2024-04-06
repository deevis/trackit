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
  class BestBuy < ::TrackedSite

    # To keep controller/view/form helpers from needing attention
    # https://stackoverflow.com/questions/4507149/best-practices-to-handle-routes-for-sti-subclasses-in-rails
    def self.model_name
      TrackedSite.model_name
    end

    def self.display_name; "BestBuy"; end

    def get_data_html(tracked_site_datum)
      discounted_amount = tracked_site_datum.data['regular_price'] - tracked_site_datum.data['price']
      discounted_amount = (discounted_amount * 100).to_i / 100.0
      discounted_display = discounted_amount > 0 ? "(-$#{discounted_amount})" : ""
      "#{tracked_site_datum.start_time.strftime("%m/%d/%Y")} : $#{tracked_site_datum.data['price']} #{discounted_display}"
    end

    # Provie the url of a page containing mulitple products to scrape
    def self.scrape_product_urls(product_index_url)
      # Define the URL to scrape
      product_index_url ||= 'https://www.bestbuy.com/site/virtual-reality-devices-and-games/virtual-reality-headsets-for-pc/pcmcat1476726957734.c?id=pcmcat1476726957734'

      # Open and read the URL
      document = Nokogiri::HTML(URI.open(product_index_url))

      # CSS Selector to find product links. This might need adjustments based on the actual page structure.      
      product_links = document.css('a[href*="/site/"]')
      product_urls = product_links.select{|link| link['href'].index("skuId")}.map do |link|
        (link['href'].start_with?('http') ? link['href'] : "https://www.bestbuy.com#{link['href']}").split("#").first
      end.uniq
      product_urls
    end

    def scrape_html(filepath=nil)
      doc = get_noko_doc(filepath)
      pricing_divs = doc.css('.pricing-price')
      # set the name if it is not set already...
      if self.name.blank?
        # div.sku-title => h1
        self.name = doc.css('.sku-title').text
        self.save!
      end
      if pricing_divs.length == 0
        inactive_message = doc.css(".inactive-product-message")&.first&.text
        if inactive_message.present?
          return { 
              price: nil, regular_price: nil, 
              unavailable: true, inactive_message: inactive_message
          }.stringify_keys
        # elsif 
          # Actually being handled correctly by .inactive-product-message
          # "This item is no longer available in new condition"
        end
      end
      pricing_div = pricing_divs[0].css('.priceView-customer-price').children.first
      regular_price = pricing_divs[0].css('.pricing-price__regular-price')&.children&.first&.text
      if pricing_div.nil?
        # This page is loading pricing via javascript...(I think...)
        js = doc.css("script").detect{|s| s['id']&.start_with?("pricing-price-")}
        if js
          json = JSON.parse(js)
          price = json.dig('app','data','customerPrice').gsub(",","").to_f
          regularPrice = json.dig('app','data','regularPrice')
        end
      else
        price = pricing_div.text.gsub(/[^\d\.]/, '').to_f
      end

      
      if regular_price.present?
        # Regular price is present when the price has been discounted...
        regular_price = regular_price.gsub(/[^\d\.]/, '').to_f if regular_price.is_a?(String)
      else
        # If not discounted, then it is regular price
        regular_price = price
      end

      # BestBuy now has a secondary call to retrieve sale pricing!
      price_info = self.get_pricing_info
      price = price_info['currentPrice']
      regular_price = price_info['regularPrice']

      data = { price: price, regular_price: regular_price }.stringify_keys
      puts "    data: #{data}"
      scrape_image(doc) if self.image.blank?
      data
    end

    def scrape_image(doc=nil)
      doc ||= get_noko_doc
      # Yay!  Bestbuy has a twitter card meta section...
      begin
        url = doc.css("head > meta").detect{|m| m['property'] == "twitter:image"}['content']
      rescue => e
        msg = "Error encountered scraping BestBuy image: #{e.message}"
        Rails.logger.error(msg)
        puts msg
      end
      set_image_from_url(url)
    end

    def get_noko_doc(filepath=nil)
      if filepath.blank?
        filepath = "tracked_site_#{self.id || 'new'}.html"
        puts "Retrieving #{filepath} from #{self.url}"

        do_curl(self.url, filepath)
      end
      puts "Nokogiri parsing #{filepath}"
      doc = Nokogiri::HTML(File.readlines(filepath).join("\n"))
    end

    # {"skuId"=>"6505166",
    #  "regularPrice"=>1899.99,
    #  "currentPrice"=>1399.99,
    #  "priceEventType"=>"onSale",
    #  "regularPriceMessageType"=>"WAS",
    #  "instantSavings"=>500.0,
    #  "totalSavings"=>500.0,
    
    # Cool bestbuy API call
    def get_pricing_info
      sku = self.url.match(/.*\/(\d*)\.p.*/)[1]
      visitor_id = "c4659b2c-2367-11ed-92c7-0ab6327b9eeb"
      url = "https://www.bestbuy.com/pricing/v1/price/item?cartTimestamp=#{Time.current.to_i}&catalog=bby&context=Product-Page&includeOpenboxPrice=true&includedealExpirationTimeStamp=true&paidMemberSkuInCart=false&paymentOptions=true&salesChannel=LargeView&skuId=#{sku}&usePriceWithCart=true&visitorId=#{visitor_id}"
      JSON.parse(do_curl(url))
    end

    def do_curl(url, filepath = nil)
      curl_command = <<~CURL
        curl -L '#{url}' \
          -H 'authority: www.bestbuy.com' \
          -H 'accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9' \
          -H 'accept-language: en-US,en;q=0.9,da;q=0.8' \
          -H 'upgrade-insecure-requests: 1' \
          -H 'x-client-id: lib-price-browser' \
          -H 'user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/101.0.4951.67 Safari/537.36' \
          --compressed
      CURL
      curl_command = "#{curl_command.squish} > #{filepath}" if filepath.present?
      puts "=" * 50
      puts curl_command
      puts "=" * 50
      `#{curl_command}`

    end

  end
end

# "https://www.bestbuy.com/pricing/v1/price/item?cartTimestamp=#{Time.current.to_i}&catalog=bby&context=Product-Page&includeOpenboxPrice=true&includedealExpirationTimeStamp=true&paidMemberSkuInCart=false&paymentOptions=true&salesChannel=LargeView&skuId=#{sku}&usePriceWithCart=true&visitorId=#{visitor_id}"


# curl 'https://www.bestbuy.com/pricing/v1/price/item?allFinanceOffers=true&cartTimestamp=1665779042392&catalog=bby&context=offer-list&includeOpenboxPrice=true&includedealExpirationTimeStamp=true&paidMemberSkuInCart=false&paymentOptions=true&salesChannel=LargeView&skuId=6505166&useCabo=true&usePriceWithCart=true&visitorId=c4659b2c-2367-11ed-92c7-0ab6327b9eeb' \
#   -H 'authority: www.bestbuy.com' \
#   -H 'accept: application/json' \
#   -H 'accept-language: en-US,en;q=0.9,da;q=0.8' \
#   -H 'cache-control: no-cache' \
#   -H 'cookie: oid=240219285; optimizelySegments=%7B%228143663043%22%3A%22direct%22%2C%228115018064%22%3A%22none%22%2C%228138082435%22%3A%22false%22%2C%228118974637%22%3A%22gc%22%7D; optimizelyBuckets=%7B%7D; google_disable_auto_signon=%7B%22meta%22%3A%7B%22CreatedAt%22%3A%222017-12-03T05%3A40%3A34.288Z%22%2C%22ModifiedAt%22%3A%222017-12-03T05%3A40%3A34.288Z%22%2C%22ExpiresAt%22%3A%229999-01-01T00%3A00%3A00.000Z%22%7D%2C%22value%22%3A%221%22%7D; track={"campaign_date":"1523201450864","campaign":"166%2CBAN_1781800_20790123_215118941","lastSearchTerm":"smart%20watch","listFacets":"","a2cTracked":"true"}; x-location-id=90258d2d7661429cb868077059e407e9#-1690637906; G_ENABLED_IDPS=google; UID=92250fbe-adc0-4d41-8bf1-24770e1a759a; locDestZip=84109; physical_dma=770; customerZipCode=84115|Y; __gsas=ID=2d6b7e04e179e65d:T=1649998920:S=ALNI_MZpdl2XYITUpPzx7NUVvptdDmk55g; __gads=ID=04404b99fd899391:T=1653643566:S=ALNI_MaTBntM7hkBs70vH_olF1WzY5qJxQ; _cs_c=1; locStoreId=527; _ga=GA1.2.1272242421.1661010788; cto_bundle=HzXZMV9ZRTk2JTJGUmV4c2lrYTRuOUhXRndwYjJvNCUyRkolMkZ3ODNoSXFNRW8lMkJaa3BuU1pCS2NhUGt3Rlp5OTRvWUVvVnh0a0xwb1BxN2pOZnFlT29XRHphZkdrV2J4Mjh6MCUyQlRrNHFMRGM3RVhlQnJlc1FVU2M4SEJ0NFRyM1ZCbmpOZnpsalRCajd2aGhiTGxQYzJnYlZwR1NxY1RnJTNEJTNE; vt=c4659b2c-2367-11ed-92c7-0ab6327b9eeb; __gpi=UID=000005c1f90694a1:T=1653643566:RT=1662080575:S=ALNI_MbJtN8CBQ4Nh4iu1bYpXcc58JovXQ; bby_prf_csc=d975de36-c502-4089-9c75-72d7070c3ca2; SID=50aab64d-0e65-4617-a810-aa97dc7e97c5; CTT=d1c5ec7978de254b34bb07b15073327f; rxVisitor=16657790208284HUNKQGBLTATNQF1QRKVQFTG3LC2U4SN; dtSa=-; COM_TEST_FIX=2022-10-14T20%3A23%3A41.499Z; AMCVS_F6301253512D2BDB0A490D45%40AdobeOrg=1; _cs_mk=0.03172430764153433_1665779032029; s_cc=true; _gcl_au=1.1.136180013.1665779039; basketTimestamp=1665779042392; sc-location-v2=%7B%22meta%22%3A%7B%22CreatedAt%22%3A%222017-08-05T19%3A59%3A16.791Z%22%2C%22ModifiedAt%22%3A%222022-10-14T20%3A24%3A04.977Z%22%2C%22ExpiresAt%22%3A%222023-10-14T20%3A24%3A04.977Z%22%7D%2C%22value%22%3A%22%7B%5C%22physical%5C%22%3A%7B%5C%22zipCode%5C%22%3A%5C%2284109%5C%22%2C%5C%22source%5C%22%3A%5C%22C%5C%22%2C%5C%22captureTime%5C%22%3A%5C%222022-07-25T23%3A46%3A55.778Z%5C%22%7D%2C%5C%22store%5C%22%3A%7B%5C%22zipCode%5C%22%3A%5C%2284115%5C%22%2C%5C%22searchZipCode%5C%22%3A%5C%2284058%5C%22%2C%5C%22storeId%5C%22%3A%5C%22527%5C%22%2C%5C%22storeHydratedCaptureTime%5C%22%3A%5C%222022-08-06T20%3A07%3A30.473Z%5C%22%2C%5C%22userToken%5C%22%3A%5C%221395b2a9-04ef-11e4-b091-00505692405b%5C%22%7D%2C%5C%22destination%5C%22%3A%7B%5C%22zipCode%5C%22%3A%5C%2284109%5C%22%7D%7D%22%7D; ZPLANK=b49e041813094ea3a09de8973892377e; s_sq=%5B%5BB%5D%5D; dtCookie=v_4_srv_1_sn_0LKJG4E7LRQ10PSQIFJ6701PK9REVHF0_app-3Aea7c4b59f27d43eb_1_app-3A1531b71cca36e130_1_app-3A21f5a3c46dc908d0_1_app-3A1b02c17e3de73d2a_1_ol_0_perc_100000_mul_1; surveyDisabled=true; bby_cbc_lb=p-browse-w; ltc=%20; bm_sz=2950D92611F18725959A39AF86A9E4A1~YAAQFJA6F+KcnrGDAQAAPHoL3xEMl2DRC/Tmle4MD66UQcWJAPnL63nYmh76O1sBXckF3nWp0UcjeRzcrT9R2zc5UOk28FK2lPeXexfiEjgI5lRpFj9mxorBXjCxHSivMPaI3CVkyXJI/MgeL2Aa+uq+Ef9oLgmJmgK/CKE307m/Gii9qLvHFnzLtKCaHQHHziuChu5TKd6PgAF99QnGpVV+9yrk1O001rU1u2ui75V0H1keKyMTw+GU4+2vmhwI9OHHuq/3yfyI+i87NIxg3eCtB/AHmEWAe0uXYYMZwyHZn6q/WtIk1clT+LXYMvGbZAI/BquZAUia4DT+TzGCfpAhTOmwvKPpkSueV43w7mM5qVj5NPAso9sLRa10P+grZoWVowzWblP2g+6KQjYTBQ==~4534323~3228983; _abck=CADCD7DB28EB4C297C049ABB7148A4FA~0~YAAQFJA6F+GcnrGDAQAAPHoL3wg13CK9tRuQ97WS2E2OojcaO9uoGzHyD3vxn2dUaLx8OMr1rL3UG/397/mG2JSwu9Ud5ahItT6DUPFEd1ohb9uRfYcG2CG8Xw0vxIu2L0u2JCbUzGy7W0YuDpy40aa4BJQZWMDAWa6NZgdL9eCH6BFg4C9+oYJHtCRnRHmXEKfzEImayOJuvY8Ot4AakbjiUBpL59QCCReNTsV/1wjtovOUMGimpNjcX+3l33ldrccFjh1LXAy9ozUk2s5eyGg5MnC9bOg3maIEaNN56gBVSMRiE5MZVUQ1MGBSBQcW82zqNV6cLgRWtixk8bqxnnZ1YnlccovEfAoQBWN1yV8B13BF8AUrgRNM0U3rEe1PAzu2T2mfvMMNkwQnO2wfAz0h4QRETjc=~-1~-1~-1; bby_rdp=l; bby_prc_lb=p-prc-w; CTE20=T; c2=Product%20Detail%20Page; AMCV_F6301253512D2BDB0A490D45%40AdobeOrg=1585540135%7CMCAID%7C2CBDEF7E051D6B9C-6000190FE0014830%7CMCMID%7C66647192546660450760683507840680510327%7CMCAAMLH-1664436785%7C9%7CMCAAMB-1665894451%7CRKhpRz8krg2tLO6pguXWp5olkAcUniQYPHaMWWgdJ3xzPWQmdj0y%7CMCOPTOUT-1665901652s%7CNONE%7CvVersion%7C4.4.0%7CMCCIDH%7C1547875654; _cs_id=15d1823d-6402-a160-a90f-9f0bc3cd249d.1658792830.59.1665894463.1665894434.1645469968.1692956830712; _cs_s=2.0.0.1665896264075; dtPC=1$294480084_61h1vAHWFHEIRAJGCGBLWRUOECUFMCMMASCCQ-0e0; dtLatC=9; rxvt=1665896281235|1665894166185' \
#   -H 'pragma: no-cache' \
#   -H 'referer: https://www.bestbuy.com/site/samsung-hw-q990b-11-1-4ch-soundbar-with-wireless-dolby-atmos-dtsx-and-rear-speakers-black/6505166.p?skuId=6505166' \
#   -H 'sec-ch-ua: "Chromium";v="106", "Google Chrome";v="106", "Not;A=Brand";v="99"' \
#   -H 'sec-ch-ua-mobile: ?0' \
#   -H 'sec-ch-ua-platform: "Windows"' \
#   -H 'sec-fetch-dest: empty' \
#   -H 'sec-fetch-mode: cors' \
#   -H 'sec-fetch-site: same-origin' \
#   -H 'user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/106.0.0.0 Safari/537.36' \
#   -H 'x-client-id: lib-price-browser' \
#   --compressed

# curl 'https://www.bestbuy.com/site/gigabyte-15-6-ips-level-240hz-gaming-laptop-intel-core-i7-11800h-32gb-memory-nvidia-geforce-rtx-3080-1tb-ssd/6479983.p?skuId=6479983' \
#   -H 'authority: www.bestbuy.com' \
#   -H 'accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9' \
#   -H 'accept-language: en-US,en;q=0.9,da;q=0.8' \
#   -H 'cache-control: no-cache' \
#   -H 'pragma: no-cache' \
#   -H 'sec-ch-ua: " Not A;Brand";v="99", "Chromium";v="101", "Google Chrome";v="101"' \
#   -H 'sec-ch-ua-mobile: ?0' \
#   -H 'sec-ch-ua-platform: "Windows"' \
#   -H 'sec-fetch-dest: document' \
#   -H 'sec-fetch-mode: navigate' \
#   -H 'sec-fetch-site: none' \
#   -H 'sec-fetch-user: ?1' \
#   -H 'upgrade-insecure-requests: 1' \
#   -H 'user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/101.0.4951.67 Safari/537.36' \
#   --compressed

