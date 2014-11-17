require File.expand_path('../boot', __FILE__)

# Pick the frameworks you want:
require "active_model/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "sprockets/railtie"
# require "rails/test_unit/railtie"

Bundler.require(*Rails.groups)

module EdoPersonalCloud
  class Application < Rails::Application
    config.autoload_paths += %W(#{config.root}/lib/settings #{config.root}/app/validators/)
    config.middleware.insert_before ActionDispatch::ParamsParser, "CatchJsonParseErrors"
    config.middleware.unshift "ErrorResponseNotifier"

    config.time_zone = "Tokyo"
    config.active_record.default_timezone = :local
    config.i18n.default_locale = :ja
    config.i18n.load_path += Dir["#{config.root}/config/locales/**/*.yml"]

    config.generators do |g|
      g.assets false
      g.helper false
      g.test_framework :rspec, fixture: true
    end
  end
end
