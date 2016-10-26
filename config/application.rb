require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Http2Rails
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
  end
end

Rails.application.configure do
  config.assets.enabled = false
  config.assets.paths << "#{Rails.root}/app/assets/stylesheets" 
  config.assets.paths << "#{Rails.root}/public" 
  
  config.public_file_server.enabled = true
end