Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  namespace :api do
    namespace :v1 do
      resources :reports, except: [:new, :edit]
      resources :users, except: [:new, :edit]
      resources :locations, except: [:new, :edit]
      resources :bike_paths, except: [:new, :edit]
      post '/login', to: "sessions#create"
    end
  end

end
