podman run --privileged -v /home/koji-sync/podman:/root/koji-sync/podman centos:8 /bin/sh /root/koji-sync/podman/script.sh


rsync -r --delete -e ssh /home/koji-sync/podman/koji/staged/ root@koji.katello.org:/mnt/koji/releases/split/yum/koji-modules/koji/staged/ -v
