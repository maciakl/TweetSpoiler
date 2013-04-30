# dontspoil.us (c) Luke Maciak 2013
# GPL v3.0
# ===

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
    #DataMapper.auto_migrate!

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
    # his username and information and then cache it if needed.
    # Generally you always want to use cached info because otherwise
    # you will hit the Twitter rate limits really fast.
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
    
    # This is for debugging. By default the error risen by
    # DataMapper upon failed save is very generic. This is the
    # only way to actually see what happens inside
    begin
        spoiler.save
    rescue DataMapper::SaveFailureError => e
        puts e.resource.errors.inspect
    end
    


    # Grab insertion ID 
    id = spoiler.id

    # Create a twitter client using the current access token
    access_token = session[:access_token]

    client = Twitter::Client.new(
                    :oauth_token => access_token.token,
                    :oauth_token_secret => access_token.secret)

    # create URL based on the insertion value
    # note that we are skipping the www to shorten it (it works)
    url = ' http://dontspoil.us/'+id.to_s

    # post message + URL to twitter as current user
    client.update(params[:tweet] + url)

    # shoot user over to the display page to see the spoiler they just created
    redirect '/'+id.to_s
    
end


get '/logout' do
    session[:request_token] = nil
    session[:access_token] = nil
    session[:username] = nil
    redirect '/'
end

get '/about' do
    erb :about
end

get '/privacy' do
    erb :privacy
end

# Fake 404 route - better than nothing
get '/error' do
    erb :e404
end

# TODO: pattern match only numerical url's
get '/:id' do

    # Display a stored spoiler

    @id = params[:id]

    spoiler = Spoiler.get(@id)
    
    # Poor man's 404 implementation. Technically I should be using the built in
    # Sinatra not_found route but since I want shortest url's possible to fit
    # in Twitter char limit I have a root level wildcard route here. This means
    # it matches just about everything and there is no way for me to tell if
    # a given url exists or not before I do a database lookup on ID. So we
    # check and redirect
    redirect '/error' if spoiler == nil

    @created = spoiler.created_at.strftime("%B %d, %Y at %l:%M %P")
    @for = spoiler.for
    @username = spoiler.user_username

    user = User.get(@username)
    
    @name = user.name
    @picture = user.pic

    spoiler_text = spoiler.spoiler

    @spoiler = spoiler_text.gsub( %r{http://[^\s<]+} ) do |url|
        if url[/(?:png|jpe?g|gif|svg)$/]
            "<img src='#{url}'/>"
        else
            "<a href='#{url}'>#{url}</a>"
        end
    end

    erb :spoiler
end
