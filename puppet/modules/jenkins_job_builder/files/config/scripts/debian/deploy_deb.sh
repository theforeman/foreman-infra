#!/bin/bash -xe

ssh -i /var/lib/workspace/workspace/deb_key/rsync_freight_key freight@deb.theforeman.org deploy ${os} ${repo}
