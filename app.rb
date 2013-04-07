require 'rubygems'
require 'bundler/setup'
require 'sinatra'
require 'oauth'
require 'twitter'
require 'data_mapper'

# Set to true for local debugging with foreman.
# This will force Foreman to output messages to STDOUT immediately
# If set to false, Foreman will queue all the puts messages and display
# them after you close it.
$stdout.sync = true

# Read the configuration from the heroku environment
# Locally these should be defined in an .env file
# You can initially pull it by using:
#       heroku config:pull
# Make sure you modify the CALLBACK_URL to point to
#       http://localhost:5000/auth
# If you don't do this, you won't be able to authenticate
# locally. Note that changes to the .env file are not
# pushed back to heroku unless you push them manually
TWITTER_KEY = ENV['TWITTER_CONSUMER_KEY']
TWITTER_SECRET = ENV['TWITTER_CONSUMER_SECRET']
CALLBACK_URL = ENV['CALLBACK_URL']

enable :sessions

# Define Data Models
# ==================

# Used for caching user information so that we
# don't have to query for it on every page load
# avoiding the rate limits
class User
    include DataMapper::Resource

    property :username, String, :key => true
    property :name, String
    property :pic, Text

    has n, :spoilers

end

# Holds the actual spoilers that will be displayed
class Spoiler
    include DataMapper::Resource

    property :id, Serial
    property :created_at, DateTime
    property :for, Text
    property :spoiler, Text

    belongs_to :user
end

# =================

configure do

    # set up DataMapper with the Heroku DB or alternatively
    # with a local SQLite database when run locally
    DataMapper.setup(:default, ENV['DATABASE_URL'] || 
                        "sqlite3://#{Dir.pwd}/demo.db")
    
    # Modify the table schema in a safe way 
    # use auto_migrate! to drop and rebuild tables if needed
    DataMapper.auto_upgrade!

    # By default DataMapper fails silently. Methods that save return false
    # This setting overrides this behavior rising an error instead
    # Better for debugging
    DataMapper::Model.raise_on_save_failure = true
end

before do
    # Create OAuth consumer using the default Twitter URL's
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
    # this will redirect the user to Twitter authorization page asking them to
    # log in and authorize the app.
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

    # Check if user is logged in. If not we query Twitter for
    # his username and information and then cache it if needed
    if session[:username] == nil

        client = Twitter::Client.new(
                    :oauth_token => access_token.token,
                    :oauth_token_secret => access_token.secret)

        tname = client.current_user.name
        tusername = client.current_user.screen_name
        tpic = client.current_user.profile_image_url

        # Cache the user information in the DB. If user does not exist this
        # will create a new record. If he exists, it will update his record
        # with the new name and picture
        current_user = User.first_or_create({:username => tusername},
                                            {:name => tname, :pic => tpic})
        session[:username] = tusername
    else
        current_user = User.get(session[:username])
    end
    
    @user = session[:username]
    @name = current_user.name
    @picture = current_user.pic
    erb :tweet
end


post '/tweet' do
    redirect '/login' if session[:access_token] == nil || session[:username] == nil

    spoiler = Spoiler.new
    spoiler.user_username = session[:username]
    spoiler.for = params[:for]
    spoiler.created_at = Time.now
    spoiler.spoiler = params[:spoiler]
    
    begin
        spoiler.save
    rescue DataMapper::SaveFailureError => e
        puts e.resource.errors.inspect
    end

    id = spoiler.id
    redirect '/'+id.to_s
    
end


get '/logout' do
    session[:request_token] = nil
    session[:access_token] = nil
    session[:username] = nil
    redirect '/'
end


get '/:id' do

    id = params[:id]

    spoiler = Spoiler.get(id)

    @created_at = spoiler.created_at #strtftime("%m/%d/%Y %l:%M %p")
    @for = spoiler.for
    @spoiler = spoiler.spoiler
    @username = spoiler.user_username

    user = User.get(@username)
    
    @name = user.name
    @picture = user.pic

    erb :spoiler
end
