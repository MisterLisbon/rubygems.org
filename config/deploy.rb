set :stages, %w(staging production)
set :default_stage, "staging"

require 'capistrano/ext/multistage'

default_run_options[:pty] = true

set :ssh_options, { :forward_agent => true }

set :application, "gemcutter"
set(:rails_env) { "#{stage}"}

role :app, "rubycentral.org"
role :web, "rubycentral.org"
role :db,  "rubycentral.org", :primary => true

# Note that this requires you run 'ssh-add' on your workstation in order to
# add your private key to the ssh agent.  If that's not good for you, just uncomment the 
# "set :deploy_via, :copy" and comment "set :deploy_via, :remote_cache"
set :scm, :git
set :repository,  "git@github.com:tcopeland/gemcutter.git"
set :repository_cache, "git_cache"
set :git_enable_submodules, 1
set :deploy_via, :remote_cache
set :git_shallow_clone, 1
set :use_sudo, false

set :group, "rubycentral"
set :user, "tom"

namespace :deploy do
  desc "Restarting mod_rails with restart.txt"
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "touch #{current_path}/tmp/restart.txt"
  end

  [:start, :stop].each do |t|
    desc "#{t} task is a no-op with mod_rails"
    task t, :roles => :app do ; end
  end

  desc "Move in database.yml for this environment"
  task :move_in_database_yml, :roles => :app do
    run "cp #{deploy_to}/shared/system/database.yml #{current_path}/config/"
  end

  # Surely there's a better way to do this.  But it's eluding me at the moment.
  desc "Move in secret settings for this environment"
  task :move_in_secret_settings, :roles => :app do
    run "cat #{deploy_to}/shared/system/secret.rb >> #{current_path}/config/environment.rb"
  end

end

namespace :delayed_job do
  desc "Start delayed_job process" 
  task :start, :roles => :app do
    run "cd #{current_path}; script/delayed_job start #{rails_env}" 
  end

  desc "Stop delayed_job process" 
  task :stop, :roles => :app do
    run "cd #{current_path}; script/delayed_job stop #{rails_env}" 
  end

  desc "Restart delayed_job process" 
  task :restart, :roles => :app do
    run "cd #{current_path}; script/delayed_job restart #{rails_env}" 
  end
end

after "deploy:start", "delayed_job:start" 
after "deploy:stop", "delayed_job:stop" 
after "deploy:restart", "delayed_job:restart"

after "deploy", "deploy:migrate"
after "deploy", "deploy:cleanup"
after "deploy:symlink", "deploy:move_in_database_yml", "deploy:move_in_secret_settings"

