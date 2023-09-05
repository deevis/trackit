class AddTimeIndexesToForecasts < ActiveRecord::Migration[7.0]
  def change
    add_index :forecasts, [:station_id, :time]
    add_index :forecasts, [:station_id, :end_time]
  end
end
