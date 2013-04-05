require 'rubygems'
require 'bundler/setup'
require 'sinatra'

# Read the configuration from the heroku environment
TWITTER_KEY = ENV['TWITTER_CONSUMER_KEY']
TWITTER_SECRET = ENV['TWITTER_CONSUMER_SECRET']

get '/' do
    erb :index
end
