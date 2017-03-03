# installation
gem 'foreman'
gem 'devise'
gem 'sidekiq'
gem 'sidekiq-unique-jobs'
gem 'activeadmin', '~> 1.0.0.pre4'
gem 'inherited_resources', git: 'https://github.com/activeadmin/inherited_resources' #rails 5

run 'gem install mailcatcher'

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


