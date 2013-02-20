set :application, "foreman-infra"
set :repository, "git://github.com/theforeman/foreman-infra.git"
set :scm, :git
set :host, "server3.theforeman.org"
set :user_sudo, false
set :deploy_via, :copy
set :deploy_to, "/etc/puppet/#{application}"
set :branch, "master"
set :copy_compression,  :gzip
set :moduledir, "/etc/puppet/modules"


role :puppetmaster, host

ssh_options[:forward_agent] = true
after "deploy:restart", "deploy:init_submodules"
after "deploy:init_submodules", "deploy:swing_symlink"

if File.exists?(".CAPUSER")
  set :user, File.open(".CAPUSER", "r").read.chomp
else
  set :user, "root"
end

namespace :deploy do
  task :init_submodules do
    run("cd #{deploy_to}/current/ && git submodule update --init")
  end

  task :swing_symlink do
    # This actually only needs to run the first time the master is deployed
    # but there isn't a good way in cap to test for existence. This is a hack.
    run("unlink #{moduledir} && ln -s #{deploy_to}/current/puppet/modules #{moduledir}")
  end
end
