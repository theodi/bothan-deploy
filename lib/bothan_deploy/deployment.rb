require 'dotenv'
Dotenv.load

require 'odlifier'

module BothanDeploy
  class Deployment
    include Sidekiq::Worker

    SOURCE_BLOB = 'https://github.com/theodi/bothan/tarball/master'

    def perform(token, params)
      @heroku = PlatformAPI.connect_oauth(token)
      @params = params
      build
    end

    def build
      @app = create_app
      @id = @app['id']
      @complete = false
      check_status
      report_status
    end

    private

    def create_app
      @heroku.app_setup.create(
        {
          app: {
            name: @params['name']
          },
          source_blob: {
            url: SOURCE_BLOB
          },
          overrides: env_overrides
        }
      )
    end

    def env_overrides
      {
        env: {
          'METRICS_API_USERNAME'        => @params['username'],
          'METRICS_API_PASSWORD'        => @params['password'],
          'METRICS_API_TITLE'           => @params['title'],
          'METRICS_API_DESCRIPTION'     => @params['description'],
          'METRICS_API_LICENSE_NAME'    => (license.nil? ? '' : license.title),
          'METRICS_API_LICENSE_URL'     => (license.nil? ? '' : license.url),
          'METRICS_API_PUBLISHER_NAME'  => @params['publisherName'],
          'METRICS_API_PUBLISHER_URL'   => @params['publisherUrl'],
          'METRICS_API_CERTIFICATE_URL' => '#'
        }
      }
    end

    def license
      Odlifier::License.define(@params['license']) if @params['license']
    end

    def check_status
      while @complete == false do
        @info = @heroku.app_setup.info(@id)
        if @info['status'] == 'pending'
          sleep 5
        else
          @complete = true
        end
      end
    end

    def report_status
      if @info['status'] == 'succeeded'
        pusher_client['app_status'].trigger('success', { url: @info['resolved_success_url'] })
      elsif @info['status'] == 'failed'
        pusher_client['app_status'].trigger('failed', { message: @info['failure_message'] })
      end
    end

    def pusher_client
      Pusher::Client.new(
        app_id: ENV['PUSHER_APP_ID'],
        key: ENV['PUSHER_KEY'],
        secret: ENV['PUSHER_SECRET'],
        host: 'api-eu.pusher.com'
      )
    end

  end
end
