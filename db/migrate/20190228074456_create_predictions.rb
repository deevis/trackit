class CreatePredictions < ActiveRecord::Migration[5.2]
  def change
    create_table :predictions do |t|
      t.references :forecast, foreign_key: true
      t.references :station, foreign_key: true
      t.datetime :start_time
      t.datetime :end_time
      t.integer :temperature
      t.string :temperature_unit, limit: 1
      t.integer :wind_speed
      t.string :wind_unit, limit: 4
      t.string :wind_direction, limit: 4
      t.string :short_forecast
      t.string :icon, limit: 30

      t.timestamps
    end
  end
end
