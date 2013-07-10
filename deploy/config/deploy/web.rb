set :application, "theforeman.org"
set :repository, "git://github.com/theforeman/theforeman.org.git"
set :scm, :git
set :host, "server2.theforeman.org"
set :user_sudo, false
set :deploy_via, :copy
set :deploy_to, "/var/www/cap/#{application}"
set :branch, "gh-pages"
set :copy_compression,  :gzip


role :web, host

ssh_options[:forward_agent] = true

after "deploy:restart", "deploy:jekyll_build"

if File.exists?(".CAPUSER")
  set :user, File.open(".CAPUSER", "r").read.chomp
else
  set :user, "root"
end

namespace :deploy do
  task :finalize_update do
  end

  task :jekyll_build do
    run "cd #{deploy_to}/current && jekyll build"
  end
end
