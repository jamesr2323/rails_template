# Rails template

Simple template for intialising a rails project that's ready to run in a Procfile environment (e.g. Heroku) with some common task already taken care of. I created this to reduce project start up time configuring the same things. Perhaps it will be useful for you too!

Sets up Devise, ActiveAdmin, Sidekiq

## Prerequisites
 - Ruby
 - Rails (tested using 5.0.1)
 - Redis (for Sidekiq) - `sudo apt-get install redis-server`
 - Postgres (although you could use another database, not tested with this)

## Usage
 - `rails new PROJECT_NAME --template=template.rb --database=postgresql`
 - `cd PROJECT_NAME`
 - `foreman start -f Procfile.dev`

That's it! You've got a running app with background processing and admin interface.