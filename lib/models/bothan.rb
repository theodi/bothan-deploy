require 'odlifier'

class Bothan < ActiveRecord::Base

  SOURCE_BLOB = 'https://github.com/theodi/bothan/tarball/master'

  attr_accessor :params

  after_create :create_app
  after_save :check_status

  def self.build_all
    Bothan.all.each { |b| b.build }
  end

  def build
    heroku.build.create(app_id, {
      source_blob: {
        url: SOURCE_BLOB
      }
    })
  end

  private

    def check_status
      @complete = false
      while @complete === false do
        info = heroku.app_setup.info(app_id)
        if info['status'] == 'pending'
          sleep 5
        else
          @complete = true
          report_status(info)
        end
      end
    end

    def report_status(info)
      if info['status'] == 'succeeded'
        pusher_client['app_status'].trigger('success', { url: info['resolved_success_url'] })
      elsif info['status'] == 'failed'
        pusher_client['app_status'].trigger('failed', { message: info['failure_message'] })
      end
    end

    def create_app
      app = heroku.app_setup.create(
        {
          app: {
            name: params['name']
          },
          source_blob: {
            url: SOURCE_BLOB
          },
          overrides: env_overrides
        }
      )
      self.update_column(:app_id, app['id'])
    end

    def heroku
      PlatformAPI.connect_oauth(token)
    end

    def env_overrides
      {
        env: {
          'METRICS_API_USERNAME'        => params['username'],
          'METRICS_API_PASSWORD'        => params['password'],
          'METRICS_API_TITLE'           => params['title'],
          'METRICS_API_DESCRIPTION'     => params['description'],
          'METRICS_API_LICENSE_NAME'    => (license.nil? ? '' : license.title),
          'METRICS_API_LICENSE_URL'     => (license.nil? ? '' : license.url),
          'METRICS_API_PUBLISHER_NAME'  => params['publisherName'],
          'METRICS_API_PUBLISHER_URL'   => params['publisherURL'],
          'METRICS_API_CERTIFICATE_URL' => '#'
        }
      }
    end

    def license
      Odlifier::License.define(params['license']) if params['license']
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
