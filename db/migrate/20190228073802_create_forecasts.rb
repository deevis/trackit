class CreateForecasts < ActiveRecord::Migration[5.2]
  def change
    create_table :forecasts do |t|
      t.references :station, foreign_key: true
      t.datetime :time

      t.timestamps
    end
  end
end
