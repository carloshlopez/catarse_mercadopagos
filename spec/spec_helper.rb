# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../test/dummy/config/environment", __FILE__)
require 'rspec/rails'
require 'rspec/autorun'
require 'fakeweb'

ENGINE_RAILS_ROOT=File.join(File.dirname(__FILE__), '../')

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[File.join(ENGINE_RAILS_ROOT, 'spec/support/**/*.rb')].each {|f| require f }


RSpec.configure do |config|
  # ## Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{ENGINE_RAILS_ROOT}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = false

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false

  # Include Engine routes (needed for Controller specs)
  config.include CatarseMercadopagos::Engine.routes.url_helpers

  # Include Catarse routes
  config.include Catarse::Application.routes.url_helpers

  config.include Devise::TestHelpers, :type => :controller

  config.include Factory::Syntax::Methods
  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with :truncation
  end

  config.before(:each) do
    Project.any_instance.stub(:store_image_url).and_return('http://www.store_image_url.com')
  end
end

RoutingFilter.active = false # Because this issue: https://github.com/svenfuchs/routing-filter/issues/36

def fixture_file(filename)
  return nil if filename.nil?
  file_path = File.expand_path(File.dirname(__FILE__) + '/fixtures/' + filename)
  File.read(file_path)
end

def mercadopagos_url(path, options = {})
  options[:https] = true if options[:https].nil?
  options[:country] ||= 'argentina'
  protocol = (options[:https] == true) ? 'https' : 'http'
  "#{protocol}://#{options[:country]}.mercadopagos.com#{path}"
end

def stub_get(path, filename, options={})
  opts = {:body => fixture_file(filename)}.merge(options)

  FakeWeb.register_uri(:get, mercadopagos_url(path), opts)
end

def stub_post(path, filename, options={})
  opts = {:body => fixture_file(filename)}.merge(options)

  FakeWeb.register_uri(:post, mercadopagos_url(path, options[:url]), opts)
end
