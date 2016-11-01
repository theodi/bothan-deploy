require 'sinatra/base'
require 'tilt/erubis'
require 'json'
require 'heroku/bouncer'
require 'platform-api'
require 'pusher'
require 'sidekiq'

require_relative 'bothan_deploy/racks'
require_relative 'bothan_deploy/deployment'

module BothanDeploy
  class App < Sinatra::Base

    use Rack::Session::Cookie, secret: ENV['BOTHAN_DEPLOY_SESSION_SECRET'], key: 'bothan_deploy_session'
    use Heroku::Bouncer,
      oauth: { id: ENV['HEROKU_OAUTH_ID'], secret: ENV['HEROKU_OAUTH_SECRET'], scope: 'write-protected' },
      secret: ENV['HEROKU_BOUNCER_SECRET'], expose_token: true

    get '/' do
      @title = 'Deploy your own Bothan'
      erb :index, layout: :default
    end

    post '/deploy' do
      halt(401) unless request.env['bouncer.token']
      heroku = PlatformAPI.connect_oauth(request.env['bouncer.token'])
      @app = heroku.app_setup.create({source_blob: {url: 'https://github.com/theodi/bothan/tarball/master'}})
      erb :index, layout: :default
    end

    # start the server if ruby file executed directly
    run! if app_file == $0
  end
end
