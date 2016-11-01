require 'sinatra/base'
require 'tilt/erubis'
require 'json'
require 'heroku/bouncer'

require_relative 'bothan_deploy/racks'
require_relative 'bothan_deploy/helpers'

module BothanDeploy
  class App < Sinatra::Base

    #use Rack::Session::Cookie, secret: ENV['BOTHAN_DEPLOY_SESSION_SECRET'], key: 'bothan_deploy_session'
    use Heroku::Bouncer,
      oauth: { id: ENV['HEROKU_OAUTH_ID'], secret: ENV['HEROKU_OAUTH_SECRET'], scope: 'write-protected' },
      secret: ENV['HEROKU_BOUNCER_SECRET'], expose_token: true

    helpers do
      include BothanDeploy::Helpers
    end

    get '/' do
      headers 'Vary' => 'Accept'

      @content = '<h1>Hello from BothanDeploy</h1>'
      @title = 'BothanDeploy'
      erb :index, layout: :default
    end

    # start the server if ruby file executed directly
    run! if app_file == $0
  end
end
