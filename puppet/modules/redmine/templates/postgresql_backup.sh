#!/bin/bash
# Backs up the OpenShift PostgreSQL database for this application
 
FILENAME="/usr/share/redmine_data/redmine.backup.sql.gz"

cd /tmp
sudo -u postgres pg_dump <%= @db_name %> | gzip > $FILENAME
