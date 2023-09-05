json.extract! tracked_site, :id, :name, :url, :category, :sub_category, :created_at, :updated_at
json.url tracked_site_url(tracked_site, format: :json)
