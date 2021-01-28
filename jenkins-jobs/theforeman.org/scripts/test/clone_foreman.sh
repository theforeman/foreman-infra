#!/bin/bash -ex

rm -rf foreman/
git clone https://github.com/theforeman/foreman --branch "${foreman_branch}"
