$:.unshift File.dirname(__FILE__)

require 'sinatra/base'
require 'tilt/erubis'
require 'json'
require 'heroku/bouncer'
require 'platform-api'
require 'pusher'
require 'sidekiq'
require 'sinatra/activerecord'
require 'json'

require 'bothan_deploy/racks'

require 'models/bothan'

module BothanDeploy
  class App < Sinatra::Base
    register Sinatra::ActiveRecordExtension
    set :database_file, '../../config/database.yml'

    use Rack::Session::Cookie, secret: ENV['BOTHAN_DEPLOY_SESSION_SECRET'], key: 'bothan_deploy_session'
    use Heroku::Bouncer,
      oauth: { id: ENV['HEROKU_OAUTH_ID'], secret: ENV['HEROKU_OAUTH_SECRET'], scope: 'write-protected' },
      secret: ENV['HEROKU_BOUNCER_SECRET'], expose_token: true, skip: lambda { |env| env['PATH_INFO'] == '/update' },
        allow_anonymous: lambda { |req| /statistics/.match(req.fullpath) }

    get '/' do
      
    end
      @title = 'Deploy your own Bothan'
      erb :index, layout: :default
    end
    
    get '/statistics' do
      @bothans = Bothan.statistics
      @title = "Total number of Bothan Deploys: #{@bothans}"
      erb :stats, layout: :default
    end

    get '/statistics.json' do
      content_type :json
      { :total_bothan_deploys => Bothan.statistics}.to_json
    end

    post '/deploy' do
      halt(401) unless request.env['bouncer.token']
      Bothan.delay.create(token: request.env['bouncer.token'], params: params)
      halt 202
    end

    post '/update' do
      request.body.rewind
      payload_body = request.body.read
      verify_signature(payload_body)
      json = JSON.parse(params[:payload])
      Bothan.delay.build_all if json['ref'] == 'refs/heads/master'
      halt 202
    end

    # start the server if ruby file executed directly
    run! if app_file == $0

    private

    def verify_signature(payload_body)
      signature = 'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), ENV['GITHUB_WEBHOOK_SECRET'], payload_body)
      if request.env['HTTP_X_HUB_SIGNATURE'].nil?
        return halt 412, "A signature is required."
      else
        if !Rack::Utils.secure_compare(signature,request.env['HTTP_X_HUB_SIGNATURE'])
          return halt 401, "The signature did not match! " +
            "Please ensure that the correct secret is being used."
        end
      end
    end

  end
end
