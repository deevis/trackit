class PopulateCurrentTempAndCurrentWind < ActiveRecord::Migration[7.0]
  def change
    Forecast.reset_column_information
    count = Forecast.where(current_temp: nil).count
    exceptions = []
    puts "Setting current temp and wind on all Forecasts...\n"
    Forecast.where(current_temp: nil).find_each.each_with_index do |f, idx|
      begin
        p = f.predictions[0] rescue nil
        if p.nil? or f.station.nil?
          f.destroy
          print "DESTROYED[#{f.id}]"
          sleep 0.1
        else
          f.current_temp = p.temperature
          f.current_wind = p.wind_speed
          f.save!
        end
      rescue => e
        exceptions << "#{e.message} : Forecast[#{f.id}]"
      end
      print "#{idx+1}/#{count}              \r"
    end
    puts "\n\nDone"
    puts "Exceptions: \n#{exceptions.join("\n")}"
  end
end
