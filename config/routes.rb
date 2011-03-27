Thingspeak::Application.routes.draw do
	# main data posts using this route
	match 'update', :to => 'channels#post_data', :as => 'update', :via => ((GET_SUPPORT) ? ['get', 'post'] : 'post')

	# handle subdomain routes
	match '/', :to => 'subdomains#index', :constraints => { :subdomain => 'api' }
	match 'crossdomain', :to => 'subdomains#crossdomain', :constraints => { :subdomain => 'api' }

	root :to => 'pages#home'

	resource :user_session
	resource 'account', :to => 'users'
	resources :users

	# specific feeds
	match 'channels/:channel_id/field/:field_id(.:format)' => 'feed#index'
	match 'channels/:channel_id/feed/entry/:id(.:format)' => 'feed#show'

	# nest feeds into channels
	resources :channels do
		resources :feed
		resources :api_keys
		resources :status
		resources :charts
	end

	match 'login' => 'user_sessions#new', :as => :login
	match 'logout' => 'user_sessions#destroy', :as => :logout
	match 'users/reset_password', :to => 'users#reset_password', :as => 'reset_password'
	match 'forgot_password', :to => 'users#forgot_password', :as => 'forgot_password'

  match ':controller(/:action(/:id(.:format)))'
end
