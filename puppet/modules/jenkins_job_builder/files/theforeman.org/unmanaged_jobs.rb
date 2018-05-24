#!/usr/bin/env ruby

require 'net/http'
require 'json'

url = File.open(ARGV.pop) { |file| file.readlines }.select { |line| line.include?('url=') }.first.gsub(/url=(.*\/\/)?/, '').chomp

payload = Net::HTTP.get(url, '/api/json?tree=jobs[name,description]')

puts JSON.parse(payload)['jobs'].select { |job| !job['description'].include?('<!-- Managed by Jenkins Job Builder -->') }.map { |job| job['name'] }.join(' ')

