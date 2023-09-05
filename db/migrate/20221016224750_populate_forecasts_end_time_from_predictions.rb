class PopulateForecastsEndTimeFromPredictions < ActiveRecord::Migration[7.0]
  def change
    Forecast.reset_column_information
    scope = Forecast.where(end_time: nil)
    count = scope.count
    completed = 0
    scope.find_in_batches do |batch|
      ActiveRecord::Base.transaction do
        batch.each do |f|
          forecast_end_time = f.predictions.last.start_time
          f.end_time = forecast_end_time
          f.save!
          completed += 1
          puts "#{completed}/#{count} : Forecast[#{f.id}]  #{f.time} => #{f.end_time}"
        rescue => e
          puts "\n ERROR: Forecast[#{f.id}] #{e.message}"
        end
      end
    end
  end
end
