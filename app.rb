require 'rubygems'
require 'bundler/setup'
require 'sinatra'
require 'oauth'
require 'twitter'
require 'data_mapper'

# local debugging with foreman
$stdout.sync = true

# Read the configuration from the heroku environment
TWITTER_KEY = ENV['TWITTER_CONSUMER_KEY']
TWITTER_SECRET = ENV['TWITTER_CONSUMER_SECRET']
CALLBACK_URL = ENV['CALLBACK_URL']

enable :sessions

# Define Data Models
# ==================

class User
    include DataMapper::Resource

    property :username, String, :key => true
    property :name, String
    property :pic, Text

    has n, :spoilers

end

class Spoiler
    include DataMapper::Resource

    property :id, Serial, :key => true
    property :username, String
    property :created_at, DateTime
    property :public, Text
    property :hidden, Text

    belongs_to :user
end

# =================

configure do
    DataMapper.setup(:default, ENV['DATABASE_URL'] || 
                        "sqlite3://#{Dir.pwd}/demo.db")
    DataMapper.auto_upgrade!
    DataMapper::Model.raise_on_save_failure = true
end

before do
    # Create OAuth consumer
    @oauth = OAuth::Consumer.new(
        TWITTER_KEY, TWITTER_SECRET, {   
            :site => 'https://api.twitter.com',
            :request_token_path => '/oauth/request_token', 
            :access_token_path => '/oauth/access_token',   
            :authorize_path => '/oauth/authorize' 
        }
    )

    # Create twitter client
    Twitter.configure do |config|
        config.consumer_key = TWITTER_KEY
        config.consumer_secret = TWITTER_SECRET
    end
end


get '/' do
    erb :index
end


get '/login' do
    request_token = @oauth.get_request_token(:oauth_callback => CALLBACK_URL)
    session[:request_token] = request_token
    redirect request_token.authorize_url
end


get '/auth' do
    request_token = session[:request_token]
    access_token = request_token.get_access_token(
        :oauth_verifier => params[:oauth_verifier]
    )
    
    session[:access_token] = access_token 
    redirect '/tweet'
end

get '/tweet' do

    redirect '/login' if session[:access_token] == nil

    access_token = session[:access_token]

    if session[:username] == nil

        client = Twitter::Client.new(
                    :oauth_token => access_token.token,
                    :oauth_token_secret => access_token.secret)

        tname = client.current_user.name
        tusername = client.current_user.screen_name
        tpic = client.current_user.profile_image_url

        current_user = User.first_or_create({:username => tusername},{:name => tname, :pic => tpic})
        session[:username] = tusername
    else
        current_user = User.get(session[:username])
    end
    
    @user = session[:username]
    @name = current_user.name
    @picture = current_user.pic
    erb :tweet
end


get '/logout' do
    session[:request_token] = nil
    session[:access_token] = nil
    session[:username] = nil
    redirect '/'
end
