#!/bin/bash -xe

export VAGRANT_DEFAULT_PROVIDER=openstack
BOX_NAME="centos7-devel"
cp -f vagrant/boxes.d/99-local.yaml.example vagrant/boxes.d/99-local.yaml
vagrant up $BOX_NAME
trap "vagrant destroy -f ${BOX_NAME}" EXIT ERR
