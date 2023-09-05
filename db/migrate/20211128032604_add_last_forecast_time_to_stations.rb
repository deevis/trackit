class AddLastForecastTimeToStations < ActiveRecord::Migration[5.2]
  def change
    add_column :stations, :last_forecast_time, :datetime
  end
end
