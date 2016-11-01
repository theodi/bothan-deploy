require 'dotenv'
Dotenv.load

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
      @app = @heroku.app_setup.create({source_blob: {url: SOURCE_BLOB}})
      @id = @app['id']
      @complete = false
      check_status
      report_status
    end

    private

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
