#!/bin/bash -ex

bundle exec rake test:foreman_virt_who_configure TESTOPTS="-v" --trace
