class AddCurrentTempAndWindToForecast < ActiveRecord::Migration[7.0]
  def change
    add_column :forecasts, :current_temp, :integer
    add_column :forecasts, :current_wind, :integer
  end
end
