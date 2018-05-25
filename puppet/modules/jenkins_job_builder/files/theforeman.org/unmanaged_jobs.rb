#!/usr/bin/env ruby

require 'net/http'
require 'json'

def managed?(job)
  job['description']&.include?('<!-- Managed by Jenkins Job Builder -->')
end

def get_jenkins_url_from_ini(ini_file)
  lines = File.open(ini_file, "r") do |file|
    file.readlines
  end

  url_line = lines.select { |line| line.include?('url=') }.first
  url = url_line.gsub(/url=(.*\/\/)?/, '').chomp
  url
end

def find_unmanaged_jobs_from_payload(json_payload)
  payload = JSON.parse(json_payload)

  um_jobs = payload['jobs'].select { |job| !managed?(job) }
  um_jobs
end

def format_jobs_for_output(jobs)
  jobs.map { |job| job['name'] }.join(' ')
end

def main
  url = get_jenkins_url_from_ini(ARGV.pop)

  payload = Net::HTTP.get(url, '/api/json?tree=jobs[name,description]')

  unmanaged_jobs = find_unmanaged_jobs_from_payload(payload)

  puts format_jobs_for_output(unmanaged_jobs)
end

if __FILE__ == $0
  main
end
