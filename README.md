[![Build Status](http://img.shields.io/travis/theodi/bothan-deploy.svg?style=flat-square)](https://travis-ci.org/theodi/bothan-deploy)
[![Dependency Status](http://img.shields.io/gemnasium/theodi/bothan-deploy.svg?style=flat-square)](https://gemnasium.com/theodi/bothan-deploy)
[![Coverage Status](http://img.shields.io/coveralls/theodi/bothan-deploy.svg?style=flat-square)](https://coveralls.io/r/theodi/bothan-deploy)
[![Code Climate](http://img.shields.io/codeclimate/github/theodi/bothan-deploy.svg?style=flat-square)](https://codeclimate.com/github/theodi/bothan-deploy)
[![License](http://img.shields.io/:license-mit-blue.svg?style=flat-square)](http://theodi.mit-license.org)

# Bothan Deploy

A Sinatra app and workers that allows deployment of a [Bothan](https://github.com/theodi/bothan) instance to Heroku. 

## Summary of features

Generate a form that elicits all the user information required to establish a Heroku hosted instance of Bothan.
Tasks/workers (?) that automate the process of deploying to Heroku

## Development

### Requirements
ruby version `2.3.1`

The application uses postgres for data persistence

### Environment variables

The following environment variables are required to test this application

HEROKU_OAUTH_ID=''
HEROKU_OAUTH_SECRET=''
HEROKU_BOUNCER_SECRET=''
BOTHAN_DEPLOY_SESSION_SECRET=''
PUSHER_APP_ID=
PUSHER_KEY=''
PUSHER_SECRET=''
GITHUB_WEBHOOK_SECRET=''

### Specific Development Instructions

This application is designed to run live hence the `.env` variables stipulated above

### Database Configuration

Execute `RACK_ENV=test bundle exec rake db:create && bundle exec rake db:migrate` to build the databases required for development and testing

### Development: Running the full application locally

execute `bundle exec rackup config.ru` to host the form on a `tcp://` port

### Tests

execute `bundle exec rake`