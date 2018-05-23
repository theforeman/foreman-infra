#!/usr/bin/ruby
#
# Copyright Foreman Maintainers 2018
# GPL-3.0
#
# This ruby script use the Scaleway API key to
# ensure that recent snapshots of a volume are taken,
# and that only the most recent snapshots are kept

SERVER          = ARGV[0]
exit 1 if SERVER.nil?

SETTINGS        = YAML.load_file("/etc/scaleway/#{SERVER}.yaml")
API_KEY         = SETTINGS[:api_key]
ORG_ID          = SETTINGS[:org_id]

require 'net/http'
require 'json'
require 'yaml'
require 'date'
require 'timeout'

NUM_SNAPS = 3
TIMEOUT   = 1800 # 30 min, snaps usually take ~10min

puts "Scaleway Snapshot Management for #{SERVER}"

def api_call(path,method='GET',args={})
  uri = URI("https://cp-ams1.scaleway.com/#{path}")

  if method == 'POST' then
    req = Net::HTTP::Post.new(uri,'Content-Type' => 'application/json')
    req.body = args.to_json
  elsif method == 'DELETE' then
    req = Net::HTTP::Delete.new(uri)
  else
    req = Net::HTTP::Get.new(uri)
  end
  req['X-Auth-Token'] = API_KEY

  res = Net::HTTP.start(uri.hostname, uri.port, :use_ssl => true) {|http|
    http.request(req)
  }

  if res.is_a?(Net::HTTPSuccess)
    if res.body.nil?
      return res.code
    else
      return JSON.parse(res.body)
    end
  else
    raise "api call failed: #{res.code} - #{res.message}"
  end
end

def get_volume_ids(name)
  json = api_call('volumes')

  json['volumes'].select {|v| v['server']['name'] == name}.map {|v| v['id'] }
end

def get_snapshots(vol_id)
  json = api_call('snapshots')

  json['snapshots'].select {|s| s['base_volume']['id'] == vol_id}
end

def create_snapshot(vol_id, server='unknown')
  body = {
    'name'         => "#{SERVER}-snapshot-#{Time.now}",
    'volume_id'    => vol_id,
    'organization' => ORG_ID
  }
  json = api_call('snapshots','POST',body)

  json['snapshot']['id']
end

# Main execution

# Loop over each volume for selected server
volumes = get_volume_ids(SERVER)
volumes.each do |vol|
  # Start by creating the snap and waiting for it to complete, takes about 10 min
  puts "Creating snapshot of #{vol}"
  snap_id = create_snapshot(vol, SERVER)
  puts "#{snap_id} in progress"
  begin
    Timeout.timeout(TIMEOUT) do
      while true
        # Wait for any status other than 'snapshotting' to avoid infinite loops if the snap fails
        break if api_call("/snapshots/#{snap_id}")['snapshot']['state'] != 'snapshotting'
        sleep 10
      end
      puts "#{snap_id} created"
    end
  rescue TimeoutError
    puts "#{snap_id} timeout in creating, please investigate"
    exit 1
  end

  # Only select 'available' snaps and limit them to NUM_SNAPS
  availables = get_snapshots(vol).select{|s| s['state'] == 'available'}
  if availables.size > NUM_SNAPS
    puts "Cleaning up snapshots on #{vol} - keeping #{NUM_SNAPS}"

    # Sort by creation time
    availables.sort_by! do |snap|
      -DateTime.parse(snap['creation_date']).to_time.to_i
    end

    availables[NUM_SNAPS..-1].each do |snap|
      id = snap['id']
      code = api_call("/snapshots/#{id}",'DELETE')
      puts "DELETE #{id}: #{code}"
    end
  end
end
