require "open-uri"
require "nokogiri"

# define the URL of the Zillow listing
zillow_url = "https://www.zillow.com/homedetails/3405-S-3650-E-Salt-Lake-City-UT-84109/12780240_zpid/"

# fetch the HTML of the Zillow listing
html = URI.open(zillow_url)

# parse the HTML using Nokogiri
doc = Nokogiri::HTML(html)

# extract the price history data using CSS selectors
price_history_data = doc.css("table.price-history-table tr")

# loop over the price history data and print each price change
price_history_data.each do |row|
  date = row.css("td.date-column").text
  price = row.css("td.price-column").text

  puts "#{date}: #{price}"
end
