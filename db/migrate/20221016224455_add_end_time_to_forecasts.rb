class AddEndTimeToForecasts < ActiveRecord::Migration[7.0]
  def change
    add_column :forecasts, :end_time, :datetime
  end
end
