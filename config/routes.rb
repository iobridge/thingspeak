Thingspeak::Application.routes.draw do

  # admin routes
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)

  # main data posts using this route
  match 'update', :to => 'channels#post_data', :via => ((GET_SUPPORT) ? [:get, :post] : :post)
  match 's/update', :to => 'channels#post_data', :via => [:get, :post]

  # handle subdomain routes
  get '/', :to => 'subdomains#index', :constraints => { :subdomain => 'api' }
  get 'crossdomain', :to => 'subdomains#crossdomain', :constraints => { :subdomain => 'api' }

  root :to => 'pages#home'

  # for api: login and get token
  match 'users/api_login', :to => 'users#api_login', :via => [:get, :post]

  # devise for authentication
  # override devise controllers and use custom sessions_controller and registrations_controller
  devise_for :users, :controllers => {:sessions => 'sessions', :registrations => 'registrations'}

  resource :pages do
    collection do
      get :home
      get :about
      get :headers
      get :social_home
      post :contact_us
    end
  end

  match 'users/reset_password/:id', :to => 'users#reset_password', :as => 'reset_password', :via => [:get, :post]
  patch 'users/change_password/:id', :to => 'users#change_password'
  post 'mailer/resetpassword', :to => 'mailer#resetpassword'

  # public user profiles
  match 'account/edit_profile' => 'users#edit_profile', :as => 'edit_profile', :via => [:get, :post]
  patch 'account/update_profile' => 'users#update_profile', :as => 'update_profile'
  # users paths
  post 'users/new_api_key' => 'users#new_api_key', :as => 'user_new_api_key'
  get 'users/:id/channels(.:format)' => 'users#list_channels', :as => 'list_channels', :constraints => { :id => /.*/ }
  get 'users/:glob' => 'users#profile', :as => 'user_profile', :constraints => { :glob => /.*/ }

  resource :user_session
  resource 'account', :to => 'users'
  resources :users

  # social channels
  get 's/' => 'pages#social_home'
  get 's/:slug' => 'channels#social_show', :constraints => { :slug => /.*/ }
  get 'channels/social_new' => 'channels#social_new'

  # search
  resources :tags

  # specific feeds
  get 'channels/:channel_id/feed(s)(.:format)' => 'feed#index'
  get 'channels/:channel_id/field/:field_id(.:format)' => 'feed#index' # not sure why this doesn't work with (s)
  get 'channels/:channel_id/fields/:field_id(.:format)' => 'feed#index' # not sure why this doesn't work with (s)
  get 'channels/:channel_id/field/:field_id/:id(.:format)' => 'feed#show' # not sure why this doesn't work with (s)
  get 'channels/:channel_id/fields/:field_id/:id(.:format)' => 'feed#show' # not sure why this doesn't work with (s)
  get 'channels/:channel_id/feed(s)/last_average(.:format)' => 'feed#last_average'
  get 'channels/:channel_id/feed(s)/last_median(.:format)' => 'feed#last_median'
  get 'channels/:channel_id/feed(s)/last_sum(.:format)' => 'feed#last_sum'
  get 'channels/:channel_id/feed/entry/:id(.:format)' => 'feed#show' # not sure why this doesn't work with (s)
  get 'channels/:channel_id/feeds/entry/:id(.:format)' => 'feed#show' # not sure why this doesn't work with (s)
  get 'channels/:channel_id/social_feed' => 'channels#social_feed'
  get 'channels/:channel_id/feed(s)/debug' => 'feed#debug'
  delete 'channels/:id/feeds' => 'channels#clear'

  # maps
  get 'channels/:channel_id/maps/channel_show' => 'maps#channel_show'
  get 'channels/:channel_id/status/recent' => 'status#recent'

  # multiple series on a chart demo
  get 'charts/multiple_series' => 'charts#multiple_series'

  # nest the following controllers inside channels
  resources :channels do
    collection do
      get :public
      get :watched
      get :realtime
    end
    member do
      get :import
      post :upload
      post :clear
      put :watch
      post :realtime_update
    end
    resources :feed

    resources :feeds, :to => 'feed'
    resources :api_keys, :except => [:show, :edit]
    resources :status
    resources :statuses, :to => 'status'
    resources :charts
    resources :maps
    resources :channels
    resources :tags
    resources :comments
    resources :windows, :only => [:index, :update] do
      member do
        get :iframe
        get :html
        put :hide
        put :display
      end
    end
  end

  get 'channels/:channel_id/private_windows' => 'windows#private_windows'
  get 'channels/:channel_id/hidden_windows' => 'windows#hidden_windows'
  match 'channels/:channel_id/windows' => 'windows#update', :via => [:post, :put]

  resources :comments do
    member do
      post :vote
    end
  end

  resources :plugins do
    collection do
      get 'private_plugins'
      get 'public_plugins'
      #get 'public'
    end
  end

  resources :devices do
    member do
      get :thingtweet_arduino_code
      get :thingtweet_arduino_select_thingtweet
      post :add_mac_address
      put :ajax_update
    end
  end

  resources :pipes

  # twitter status update (version 1)
  match 'apps/thingtweet/1/statuses/update(.:format)' => 'thingtweets#update', :via => [:get, :post]
  match 'apps/thingtweet/1/statuses/update_debug(.:format)' => 'thingtweets#update_debug', :via => [:get, :post]


  # thinghttp action
  match 'apps/thinghttp/send_request' => 'thinghttp#send_request', :via => [:get, :post]

  # process responses for tweetcontrol
  match 'apps/tweetcontrol/process_response' => 'tweetcontrol#process_response', :via => [:get, :post]

  # apps and nested controllers
  scope 'apps' do
    resources :thingtweets do
      collection do
        get :authorize_response
      end
      member do
        put :new_api_key
      end
    end
    resources :thinghttp do
      resources :header
      member do
        put :new_api_key
      end
    end
    resources :talkbacks do
      member do
        put :new_api_key
      end
    end
    resources :tweetcontrol
    resources :reacts
    resources :timecontrols
  end

  # talkback api
  delete 'talkbacks/:talkback_id/commands', :to => 'commands#destroy_all'
  delete 'talkbacks/:talkback_id/commands/destroy_all', :to => 'commands#destroy_all'
  resources :talkbacks do
    resources :commands do
      collection do
        match :execute, :via => [:post, :get]
        delete :destroy_all
      end
    end
  end

  resources :apps, :only => ['index']

  # admin signups by day
  get 'admin/signups', :as => 'admin_signups', :to => 'admin/users#signups'
  # admin list of all email addresses
  get 'admin/emails', :as => 'admin_emails', :to => 'admin/users#emails'

  # app shortcuts
  get 'apps/thingtweet', :to => 'thingtweets#index'
  get 'apps/react', :to => 'react#index'

  # docs
  get 'docs(/:action)', :to => 'docs'

  # users
  devise_scope :user do
    match 'login', to: "devise/sessions#new", :via => [:get, :post]
    match 'logout', to: "devise/sessions#destroy", :via => [:get, :post]
  end

  # streaming routes
  match '/stream/channels/:id/feeds(.:format)', to: 'stream#channel_feed', :via => [:get, :post]

  # add support for CORS preflighting (matches any OPTIONS route up to 5 levels deep)
  # examples: /talkbacks, /talkbacks/4, /talkbacks/4/commands, /talkbacks/4/commands/6, /apps/thingtweet/1/statuses/update
  match '/:foo(/:foo(/:foo(/:foo(/:foo))))', :to => 'cors#preflight', :via => 'options'

  #match ':controller(/:action(/:id(.:format)))', :via => :all
end

