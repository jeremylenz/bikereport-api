Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  get '/__webpack_hmr', to: "api/v1/sessions#wtf"
  namespace :api do
    namespace :v1 do
      resources :reports, except: [:new, :edit]
      resources :users, except: [:new, :edit]
      resources :locations, except: [:new, :edit]
      resources :bike_paths, except: [:new, :edit]
      resources :images, only: [:index]
      post '/login', to: "sessions#create"
      post '/oauth', to: "sessions#get_oauth_string"
      post '/facebook_oauth', to: "sessions#get_fb_access_token"
      get '/twitter', to: "sessions#collect_oauth_verifier"
      post '/testimageupload', to: "images#upload"
    end
  end

end
