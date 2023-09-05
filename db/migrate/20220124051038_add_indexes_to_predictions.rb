class AddIndexesToPredictions < ActiveRecord::Migration[5.2]
  def change
    add_index :predictions, [:station_id, :start_time]
  end
end
