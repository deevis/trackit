class AddMinMaxDiffToForecasts < ActiveRecord::Migration[5.2]
  def change
    add_column :forecasts, :temp_min, :integer
    add_column :forecasts, :temp_max, :integer
    add_column :forecasts, :temp_diff, :integer
    add_column :forecasts, :temp_diff_hours, :integer
    add_column :forecasts, :temp_diff_per_hour, :float

    add_column :forecasts, :wind_min, :integer
    add_column :forecasts, :wind_max, :integer
    add_column :forecasts, :wind_diff, :integer
    add_column :forecasts, :wind_diff_hours, :integer
    add_column :forecasts, :wind_diff_per_hour, :float

    add_index :forecasts, :temp_diff
    add_index :forecasts, :wind_diff
  end
end
