Rails.application.routes.draw do
  resources :tracked_site_product_indices do
    member do
      get :import_products
    end
  end

  devise_for :users
  
  resources :tracked_sites do
    member do
      get :scrape_latest
      post :add_child_variant
    end
  end
  
  resources :stations do
    member do 
      get :retrieve_hourly_forecast
    end
    collection do 
      get :from_lat_lon_form
      post :create_from_lat_lon 
    end
  end
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  resources :forecasts
  root "stations#index"
end
