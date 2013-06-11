require 'capistrano_colors'
set :stages, %w(web puppetmaster yum)
require 'capistrano/ext/multistage'

ssh_options[:keys] = [
  File.join(ENV["HOME"], ".ssh", "id_rsa"),
  File.join(ENV["HOME"], ".ssh", "web_id_rsa"),
  File.join(ENV["HOME"], ".ssh", "deploy_id_rsa")
]

namespace :deploy do
  [:start, :stop, :restart, :finalize_update].each do |noop|
    desc "#{noop} is not needed"
  end
end
