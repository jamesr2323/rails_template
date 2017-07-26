# installation
gem 'foreman'
gem 'devise'
gem 'sidekiq'
gem 'sidekiq-unique-jobs'
gem 'activeadmin', '~> 1.0.0.pre4'
gem 'inherited_resources', git: 'https://github.com/activeadmin/inherited_resources' #rails 5
gem 'bootstrap-sass', '~> 3.3.6'
gem 'jquery-ui-rails', '~> 4.2.1' 
gem 'puma'

run 'gem install mailcatcher'

run 'rails g controller home index'
route "root to: 'home#index'"

# HTML Template
create_file './app/views/layouts/_alerts.html.erb' do <<-EOF
<% if notice %>
  <p class="alert alert-info alert-dismissable">
    <a href="#" class="close" data-dismiss="alert" aria-label="close">&times;</a>
    <%= notice %>
  </p>
<% end %>
<% if alert %>
  <p class="alert alert-danger alert-dismissable">
    <a href="#" class="close" data-dismiss="alert" aria-label="close">&times;</a>
    <%= alert %>
  </p>
<% end %>
EOF
end

create_file './app/views/layouts/_nav.html.erb', ''

gsub_file './app/views/layouts/application.html.erb', '<%= yield %>' do <<-EOF
<%= render "layouts/nav" %>

    <div class="container">
      <%= render "layouts/alerts" %>
      <%= yield %>
    </div>
EOF
end

insert_into_file './app/views/layouts/application.html.erb', after: '<%= csrf_meta_tags %>' do <<-EOF
  <meta name="viewport" content="width=device-width, initial-scale=1">
EOF
end

# Procfiles
# Production
create_file 'Procfile' do <<-EOF
web: bundle exec puma -C ./config/puma.rb
sidekiq: bundle exec sidekiq -C ./config/sidekiq.yml -r ./config/boot.rb
EOF
end

#Dev
create_file 'Procfile.dev' do <<-EOF
web: bundle exec puma -C ./config/puma.rb
sidekiq: bundle exec sidekiq -C ./config/sidekiq.yml -r ./config/boot.rb
redis: redis-server
mail: ruby -rbundler/setup -e "Bundler.clean_exec('mailcatcher', '--foreground')" 
EOF
end

# Sidekiq config
create_file './config/sidekiq.yml' do <<-EOF
:concurrency: 15
:queues:
- default
- [mailers, 2]
:dynamic: true
EOF
end

# Puma config
create_file './config/puma.rb' do <<-EOF
@env = ENV['RACK_ENV'] || 'development'

@port = ENV['PORT'] || 5000

workers Integer(ENV['WEB_CONCURRENCY'] || 2)
threads_count = Integer(ENV['RAILS_MAX_THREADS'] || 10)

threads threads_count, threads_count

preload_app!

environment @env

port @port
EOF
end

after_bundle do
  # Devise (authentication)
  run "spring stop"
  generate "devise:install"
  model_name = ask("What would you like the admin user model to be called? [user]")
  model_name = "user" if model_name.blank?
  generate "devise", model_name

  # Active Admin
  run "rails g active_admin:install --skip-users"

  #database
  database_name = ask("What would you like dev database to be called? [database_name]")
  username = ask("Database username? [username]")
  password = ask("Database password? [password]")

  create_file '.env' do <<-EOF
DATABASE_URL=postgres://#{username}:#{password}@localhost:5432/#{database_name}
  EOF
  end

  run "psql -c 'CREATE DATABASE #{database_name}'"
  command = "CREATE USER #{username} SUPERUSER PASSWORD '#{password}'"
  run "psql -c \"#{command}\""
  run "foreman run rake db:migrate"
  run "foreman run rake db:seed"

  # git
  append_file '.gitignore' do <<-EOF
.env
  EOF
  end

  git :init
  git add: "."
  git commit: %Q{ -m 'Initial commit' }
end


