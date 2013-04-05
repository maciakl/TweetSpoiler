require 'rubygems'
require 'bundler/setup'
require 'sinatra'
require 'oauth'
require 'twitter'

# Read the configuration from the heroku environment
TWITTER_KEY = ENV['TWITTER_CONSUMER_KEY']
TWITTER_SECRET = ENV['TWITTER_CONSUMER_SECRET']
CALLBACK_URL = ENV['CALLBACK_URL']

enable :sessions

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
    access_token = session[:access_token]
    client = Twitter::Client.new(
                            :oauth_token => access_token.token,
                            :oauth_token_secret => access_token.secret)

   @user = client.current_user.name
   erb "Hello <%=@user%>!"
end


get '/logout' do
    session[:request_token] = nil
    session[:access_token] = nil
end
