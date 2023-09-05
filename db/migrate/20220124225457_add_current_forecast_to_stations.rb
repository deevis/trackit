class AddCurrentForecastToStations < ActiveRecord::Migration[5.2]
  def change
    add_reference :stations, :current_forecast, index: true
  end
end
