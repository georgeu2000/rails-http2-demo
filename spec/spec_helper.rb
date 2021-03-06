# Config
ENV[ 'RAILS_ENV' ] = 'test'
ENV[ 'RACK_ENV' ] = 'test'

# Gems
require File.expand_path('../../config/environment', __FILE__)
require 'rspec/rails'
require 'capybara/rspec'

require './lib/scripts/server'

WebMock.disable_net_connect!( allow_localhost:true )

# Rack Driver does not make bonafide requests
Capybara.default_driver = :selenium
# Capybara.server_port = 8080
Capybara.run_server = false

RSpec.configure do |config|
  config.include Rack::Test::Methods
  config.include Capybara::DSL
  config.include FactoryGirl::Syntax::Methods

  config.filter_run_including focus: true
  config.run_all_when_everything_filtered = true
  config.infer_spec_type_from_file_location!

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups

  config.backtrace_exclusion_patterns = [
    /gems/
  ]

  config.before(:suite) do
    @thread = Thread.new{ start_server( secure:true, port:8080 )}
    sleep 0.1
  end

  config.before(:each) do
  end

  config.after(:suite) do
    puts "\nStopping server."
    @thread.kill if @thread
  end
end
