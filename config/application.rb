require File.expand_path('../boot', __FILE__)

require 'rails/all'

Bundler.require(:default, Rails.env)

module Thingspeak
  class Application < Rails::Application

    # Custom directories with classes and modules you want to be autoloadable.
    # config.autoload_paths += %W(#{config.root}/extras)
    config.autoload_paths += %W(#{config.root}/lib)

    # remove active admin paths if clockwork gem is used
    config.eager_load_paths -= %W(#{config.root}/app/admin) if $clockwork == true

    # fix invalid utf8 characters
    config.middleware.insert_before "Rack::Runtime", Rack::UTF8Sanitizer

    # allow xml params
    config.middleware.insert_after ActionDispatch::ParamsParser, ActionDispatch::XmlParamsParser

    # allow frames to work
    config.action_dispatch.default_headers = { 'X-Frame-Options' => 'ALLOWALL' }

    # Activate observers that should always be running.
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # must be placed before other config.i18n lines
    config.i18n.enforce_available_locales = false

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    config.i18n.default_locale = :en

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]
  end
end

