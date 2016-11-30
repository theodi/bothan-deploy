require 'coveralls'
Coveralls.wear_merged!

require 'dotenv'
Dotenv.load

ENV['RACK_ENV'] = 'test'

require 'rack/test'
require 'bothan_deploy'
require 'database_cleaner'

DatabaseCleaner.strategy = :truncation
OmniAuth.config.test_mode = true

RSpec.configure do |config|

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.order = :random

  include Rack::Test::Methods
  def app
    BothanDeploy::App
  end

  def login!
    get '/'
    follow_successful_oauth!
  end

  def follow_successful_oauth!(fetched_user_info = {})
    # /auth/heroku (OAuth dance starts)
    OmniAuth.config.mock_auth[:heroku] = OmniAuth::AuthHash.new(provider: 'heroku', credentials: {token:'12345', refresh_token:'67890'})
    expect(last_response.location).to eq("http://#{Rack::Test::DEFAULT_HOST}/auth/heroku")
    follow_redirect!

    # stub the user info that will be fetched from Heroku's API with the token returned with the authentication
    fetched_user_info = default_fetched_user_info.merge!(fetched_user_info)
    expect_any_instance_of(Heroku::Bouncer::Middleware).to receive(:fetch_user) { fetched_user_info }

    # /auth/callback (OAuth dance finishes)
    expect(last_response.location).to match /auth\/heroku\/callback/
    expect(last_response.status).to eq(302)
    follow_redirect!
  end

  def default_fetched_user_info
    { 'email' => 'joe@a.com', 'id' => 'uid_123@heroku.com', 'allow_tracking' => true, 'oauth_token' => '12345' }
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end
