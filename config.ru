require 'dotenv'
Dotenv.load

require File.join(File.dirname(__FILE__), 'lib/bothan_deploy.rb')

run BothanDeploy::App
