#!/bin/bash -ex

[ -e plugin ] && rm -rf plugin/
git clone -b ${plugin_branch} ${plugin_repo} plugin
