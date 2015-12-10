#!/bin/bash -ex

# Link hammer_cli from github
echo 'gem "hammer_cli", :github => "theforeman/hammer-cli"' > Gemfile.local

# Retry as rubygems (being external to us) can be intermittent
while ! bundle install --without=development; do
  (( c += 1 ))
  if [ $c -ge 5 ]; then
    echo "bundle install continually failed" >&2
    exit 1
  fi
done

bundle exec rake pkg:generate_source ci:setup:minitest test TESTOPTS="-v"
