TweetSpoiler
============

Sinatra app planned for Heroku platform. Not much here yet.

Prerequistes
------------

Install using bundler:

    bundle install

Also, get Heroku toolkit.

Development
-----------

Install heroku config plugin:

    heroku plugins:install git://github.com/ddollar/heroku-config.git

Now pull the `.env` file from heroku servers:

    heroku config:pull

If you make changes to the `.env` file push it using:

    heroku config:push

Do not commit to github as this will reveal your API keys.

To run the app locally use:

    foreman start

Foreman should be able to obtain config values from the `.env` file.

Deployment
----------

To deploy:

    git push
    git push heroku master
