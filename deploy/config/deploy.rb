require 'capistrano_colors'
set :stages, %w(web puppetmaster)
require 'capistrano/ext/multistage'

namespace :deploy do
  [:start, :stop, :restart, :finalize_update].each do |noop|
    desc "#{noop} is not needed"
  end
end
