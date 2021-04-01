#!/bin/bash

podman run --privileged -v ./:/root/koji-sync/podman centos:8 /bin/sh /root/koji-sync/podman/rhel8-split.sh 

if [ $? == 0 ]
then
    rsync -r --delete -e ssh ./koji/staged/x86_64/RHEL-8-001/ root@koji.katello.org:/mnt/koji/releases/split/yum/koji-modules/koji/staged/x86_64/RHEL-8-001/  -v
    rsync -r --delete -e ssh ./koji/staged/x86_64/RHEL-8-001-mod/ root@koji.katello.org:/mnt/koji/releases/split/yum/koji-modules/koji/staged/x86_64/RHEL-8-001-mod/ -v
fi
