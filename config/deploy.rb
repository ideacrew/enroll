# config valid only for current version of Capistrano
lock '~> 3.14.1'

set :application, 'trunk'
set :repo_url, 'https://github.com/ideacrew/enroll.git'

# Default branch is :master
# ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }.call

# Default deploy_to directory is /var/www/my_app_name
set :deploy_to, '/var/www/deployments/enroll'
set :rails_env, 'production'

# Default value for :scm is :git
# set :scm, :git
# set :scm, :gitcopy

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug
set :bundle_binstubs, false
set :bundle_flags, "--quiet"
set :bundle_path, nil

# Default value for :pty is false
set :pty, true

# Default value for :linked_files is []
set :linked_files, (fetch(:linked_files, []) | ['config/mongoid.yml', 'config/initializers/devise.rb', 'config/secrets.yml', "config/environments/production.rb", "config/symmetric-encryption.yml", 'config/saml.yml', 'config/unicorn.rb', 'eyes/enroll.eye.rb', 'config/ssl/wfpk.pem'])

# Default value for linked_dirs is []
set :linked_dirs, fetch(:linked_dirs, []).push('log', 'pids', 'eye', "public/sbc")

# capistrano/rails setup
set :assets_roles, [:web, :app]

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5

# FIXME: Fix when assets are generated and linked

namespace :assets do
  desc "Kill all the assets"
  task :refresh do
    on roles(:web) do
#      execute "rm -rf #{shared_path}/public/assets/*"
      within release_path do
        with rails_env: fetch(:rails_env) do
          puts("Setting to review environment.") if ENV['ENROLL_REVIEW_ENVIRONMENT']
          execute("cd #{release_path} && rm -rf node_modules && rm -f package-lock.json")
          execute("cd #{release_path} && nvm use 10 && yarn install")
          execute :rake, "assets:clobber"
          execute("cd #{release_path} && nvm use 10 && RAILS_ENV=production NODE_ENV=production bundle exec rake assets:precompile")
          execute :rake, "seed:translations[db/seedfiles/english_translations_seed.rb]"
          # TODO: ME is committed to this branch by default
          # client_variabe = ENV['CLIENT'].downcase || ENV['client'].downcase
          # puts("Switching to #{client_variabe} configuration.") unless client_variabe.nil?
          # execute :rake, "configuration:client_configuration_toggler client='#{client_variabe}'" unless client_variabe.nil?
          # puts("No client configuration present, using current committed configuration.") if client_variabe.nil?
        end
      end
    end
  end
end
after "deploy:updated", "assets:refresh"

namespace :deploy do
  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 20 do
      sudo "service eye_rails reload"
    end
  end

  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
    end
  end
end

after "deploy:publishing", "deploy:restart"
