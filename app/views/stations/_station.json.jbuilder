json.extract! station, :id, :name, :code, :city, :state, :data, :created_at, :updated_at
json.url station_url(station, format: :json)
