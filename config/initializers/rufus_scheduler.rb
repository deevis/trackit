require 'rufus-scheduler'

scheduler = Rufus::Scheduler.new

scheduler.every '4h' do
  Station.retrieve_new_forecasts
end

scheduler.every '5h' do 
  TrackedSite.scrape_latest
end