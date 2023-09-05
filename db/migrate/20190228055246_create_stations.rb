class CreateStations < ActiveRecord::Migration[5.2]
  def change
    create_table :stations do |t|
      t.string :name
      t.string :code
      t.string :city
      t.string :state
      t.json :data

      t.timestamps
    end
  end
end
