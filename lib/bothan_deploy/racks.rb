require 'rack/conneg'

module BothanDeploy
  class App < Sinatra::Base
    set :public_folder, 'public'
    set :views, 'views'
  end
end
