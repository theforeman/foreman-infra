# provides a "random" value to cron based on the last bit of the machine IP address.
# used to avoid starting a certain cron job at the same time on all servers.
# if used with no parameters, it will return a single value between 0-59
# first argument is the occournce within a timeframe, for example if you want it to run 2 times per hour
# the second argument is the timeframe, by default its 60 minutes, but it could also be 24 hours etc
#
# example usage
# string_to_cron('foo') - returns one value between 0..59
require 'digest/sha1'

module Puppet::Parser::Functions
  newfunction(:string_to_cron, :type => :rvalue) do |args|
    mod = args[1].nil? ? 60 : args[1].to_i
    Digest::SHA1.hexdigest(args[0]).hex % mod
  end
end
