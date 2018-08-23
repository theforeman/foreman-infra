#!/usr/bin/env ruby

require 'net/http'
require 'json'

def help
  puts "USAGE:\t#{__FILE__} JENKINS_JOB_BUILDER_INIFILE"
end

def managed?(job)
  return false unless job['description']
  job['description'].include?('<!-- Managed by Jenkins Job Builder -->')
end

def get_jenkins_url_from_ini(ini_file)
  regex = /url\s?=(.*\/\/)?/

  lines = File.open(ini_file, "r") do |file|
    file.readlines
  end

  url_line = lines.select { |line| line =~ regex }
  fail "no url found in [ #{ini_file} ]" if url_line.empty?

  url_line.first.gsub(regex, '').chomp
end

def find_unmanaged_jobs_from_payload(json_payload)
  payload = JSON.parse(json_payload)

  payload['jobs'].reject { |job| managed?(job) }
end

def format_jobs_for_output(jobs)
  jobs.map { |job| job['name'] }.join(' ')
end

def main
  fail "must supply ini file" if ARGV.empty?
  fail "too many arguments" if ARGV.size > 1

  inifile = ARGV.pop

  url = get_jenkins_url_from_ini(inifile)
  fail "url is blank" unless url

  payload = Net::HTTP.get(url, '/api/json?tree=jobs[name,description]')

  unmanaged_jobs = find_unmanaged_jobs_from_payload(payload)

  unless unmanaged_jobs.empty?
    %x[jenkins-jobs --conf #{inifile} delete --jobs-only #{format_jobs_for_output(unmanaged_jobs)}]
  end
end

if __FILE__ == $0
  begin
    main
  rescue RuntimeError => e
    puts "ERROR BEEP BOOP:"
    puts "\t#{e.message}"
    puts
    help
  end
end
