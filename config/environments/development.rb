Thingspeak::Application.configure do
  # Settings specified here will take precedence over those in config/environment.rb

  # required by devise
  config.action_mailer.default_url_options = { :host => 'localhost:3000' }

  # In the development environment your application's code is reloaded on
  # every request.  This slows down response time but is perfect for development
  # since you don't have to restart the webserver when you make code changes.
  config.cache_classes = false

  config.eager_load = false

  config.assets.prefix = "/dev-assets"

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = true

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  config.assets.debug = true

end

