#!/bin/bash

LOGPREFIX="/var/log/httpd/web-https_access_ssl.log-"
OUTPUT=/var/log/rss-stat

for logfile in ${LOGPREFIX}*; do
  logsuffix=${logfile#${LOGPREFIX}}
  outfile="${OUTPUT}/rss-stat-${logsuffix}.gz"
  if [[ ! -f ${outfile} ]]; then
    grep 'feed.xml.*"Foreman/' ${logfile} | gzip > ${outfile}
  fi
done
