#!/bin/bash

# Semi-crude script to run daily for doing initial parsing of apache logs to
# remove lines we definitely don't want. It gets:
#
# * only successful requests (code == 200)
# * only GET requrests
# * only actual packages (strings ending in .rpm or .deb)
# * strips out "source", "tfm" and "rubygem" from the rpms to distinguish
#   foreman packages from dependencies
#
# This reduces the apache logs by a factor of about 20, which can then be
# downloaded for further intensive processing (by date, version, user-agent,
# etc) - date processing is particularly cpu instensive, so it's best kept off
# the webserver.
#
# This script is intended to run daily on the latest logfile, however, since it
# is possible that a logrotation has happened overnight, the last *two* files
# are parsed. Files are datestamped with a one-week cleanup.

debs=`ls -1rt /var/log/httpd/deb_access.log*|tail -n2`
yums=`ls -1rt /var/log/httpd/yum_access.log*|tail -n2`
date=`date '+%Y%m%d'`
ldir='/var/cache/parsed_apache_logs'

mkdir -p $ldir

echo -n "Parsing:"
echo $debs
grep "\s200\s" $debs \
  | grep "\"GET" \
  | grep "\.deb\s" \
  > ${ldir}/deb_downloads.${date}.log

echo -n "Parsing:"
echo $yums
grep "\s200\s" $yums \
  | grep "\"GET" \
  | grep "\.rpm\s" \
  | grep -v "\/source\/" \
  | egrep -v "/(releases|nightly)/.*(tfm|rubygem)" \
  > ${ldir}/yum_downloads.${date}.log

# Clean up old backups over a week old
find $ldir -mtime +6 -delete
