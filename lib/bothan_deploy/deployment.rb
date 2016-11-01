module BothanDeploy
  class Deployment

    SOURCE_BLOB = 'https://github.com/theodi/bothan/tarball/master'

    def initialize(token, params)
      @heroku = PlatformAPI.connect_oauth(token)
      @params = params
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
        Pusher['app_status'].trigger('success', { url: @info['resolved_success_url'] })
      elsif @info['status'] == 'failed'
        Pusher['app_status'].trigger('failed', { message: @info['failure_message'] })
      end
    end

  end
end
