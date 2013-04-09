TweetSpoiler: aka the dontspoil.us Service
==========================================

Source code for the http://dontspoil.us service. Simple online service for
posting spoilers on Twitter in a polite an unobtrusive way. Instead of
spelling them right in the tweet you post them to this service and a tweet
with a link to the spoiler is auto-generated in your timeline.

Designed to run on the Heroku cloud hosting platform.

Dependencies
------------

Here are some of the main dependencies:

* [Heroku][he] account
* [PostgreSQL][po] Heroku add-in
* [Ruby][rb] language
* [Sinatra][si] framework
* [OAuth][oag] gem
* [Twitter][twg] gem
* [DataMapper][dm] ORM gem

Building
--------

To build on Ubuntu you need the following dependencies in addition to Ruby and Gems:

    sudo aptitude install libsqlite3-dev
    sudo aptitude install liboq-dev

On windows you will need to download SQLite and extract the `sqlite3.dll` into 
your Ruby `bin` directory. On most systems this will be something like:

    c:\Ruby\bin

Once those are on the system install all the other dependencies using bundler:

    bundle install

Finally, you need to, get [Heroku Toolbelt][to]. On Ubuntu you can just run:

    wget -qO- https://toolbelt.heroku.com/install-ubuntu.sh | sh

This will download and install it for you. On Windows use the default installer.
Note: install it to a path without spaces (eg. `c:\heroku`) - otherwise you
will have a bad time.

While you are at it, add a PostreSQL add-in in your Heroku account via the
website - this is probably easiest.

Install heroku config plugin using the heroku toolbelt:

    heroku plugins:install git://github.com/ddollar/heroku-config.git

Now pull the `.env` file from heroku servers:

    heroku config:pull

It should already contain your database connection string. Update the `.env` 
file with your Twitter API keys then push it back using:

    heroku config:push

After you push, add the following value to the `.env` file:

    CALLBACK_URL=http://localhost:5000/auth

This will let you authenticate your app while running locally. When you are ready
to deploy you will need to set that key via the command line for your production
environment:

    heroku config:set CALLBACK_URL=http://yourdomain.tld/auth

Never commit the `.env` file to github as this will reveal your API keys.

To run the app locally use:

    foreman start

Foreman should be able to obtain config values from the `.env` file.

Deployment
----------

To deploy:

    git push
    git push heroku master


TODO
----

* ~Better Readme~
* Ability to edit spoilers you created
* Ability to delete spoilers you created
* Admin panel of some sort
* Captcha to prevent spam

[rb]: http://rubylang.org
[he]: http://heroku.com
[si]: http://sinatrarb.com
[twg]: https://github.com/jnunemaker/twitter
[oag]: https://github.com/pelle/oauth
[dm]: http://datamapper.org/
[po]: https://postgres.heroku.com/

[to]: https://toolbelt.heroku.com/
