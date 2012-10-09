ENV['RAILS_ENV'] ||= 'test'
require 'rubygems'
require 'spork'

# SimpleCov calculates test coverage on rake. Output at 'coverage/index.html'
require 'simplecov'

# Start SimpleCov and exclude directories
SimpleCov.start do
  add_filter "/support/"
  add_filter "/initializers/"
  add_filter "/lib/"
end

Spork.prefork do
  require File.expand_path('../../config/environment', __FILE__)
  require 'rspec/rails'
  require 'rspec/autorun'
  require 'turnip/capybara'
  require 'email_spec'
  Dir[Rails.root.join('spec/support/**/*.rb')].each {|f| require f }

  Capybara.javascript_driver = :webkit
  DatabaseCleaner.strategy = :truncation

  RSpec.configure do |config|
    config.infer_base_class_for_anonymous_controllers = false
    config.include(ActionView::Helpers::TextHelper)
    config.include(DelayedJob::Matchers)
    config.include(EmailSpec::Helpers)
    config.include(EmailSpec::Matchers)
    config.include(FactoryGirl::Syntax::Default)
    config.mock_with(:mocha)
    config.use_transactional_fixtures = true

    Delayed::Worker.delay_jobs = true

    config.before(:each, type: :request) do
      ActionMailer::Base.deliveries.clear
      Delayed::Worker.delay_jobs = false
      Dotenv.load
    end
  end
end

Spork.each_run do
  FakeYammer.reset
  DatabaseCleaner.clean
end
