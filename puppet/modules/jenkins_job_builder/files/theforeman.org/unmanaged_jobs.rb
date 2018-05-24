#!/usr/bin/env ruby

require 'net/http'
require 'json'

payload = Net::HTTP.get('ci.theforeman.org', '/api/json?tree=jobs[name,description]')

puts JSON.parse(payload)['jobs'].select { |job| !job['description'].include?('<!-- Managed by Jenkins Job Builder -->') }.map { |job| job['name'] }.join(' ')
