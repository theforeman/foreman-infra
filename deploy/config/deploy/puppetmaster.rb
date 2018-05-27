set :application, "foreman-infra"
set :repository, "https://github.com/theforeman/foreman-infra.git"
set :scm, :git
set :host, "puppetmaster.theforeman.org:8122"
set :user_sudo, false
set :deploy_via, :copy
set :deploy_to, "/etc/puppetlabs/code/#{application}"
set :branch, "master"
set :copy_compression,  :gzip
set :moduledir, "/etc/puppetlabs/code/environments/production/modules"

role :puppetmaster, host

ssh_options[:forward_agent] = true
ssh_options[:keys] = [File.join("/var/lib/jenkins", "slaves", "id_rsa")] if File.exists?("/var/lib/jenkins")

after "deploy:restart", "deploy:init_submodules"
after "deploy:init_submodules", "deploy:swing_symlink"

if File.exists?(".CAPUSER")
  set :user, File.open(".CAPUSER", "r").read.chomp
else
  set :user, "root"
end

namespace :deploy do
  task :init_submodules do
    run("rm #{deploy_to}/current/puppet/modules/augeasproviders/.gitmodules")
    run("cd #{deploy_to}/current/ && git submodule update --init")
  end

  task :swing_symlink do
    # This actually only needs to run the first time the master is deployed
    # but there isn't a good way in cap to test for existence. This is a hack.
    # We can't use a symlink as the puppet::server class enforces a directory
    # so just sync up the files
    run("rsync -aqx --delete-after --exclude=.git #{deploy_to}/current/puppet/modules/ #{moduledir}/")
  end
end
