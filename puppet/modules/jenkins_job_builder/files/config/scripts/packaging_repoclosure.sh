#!/bin/bash

if [ ${os#f} != $os ]; then
  osname=Fedora
  osver=${os#f}
elif [ ${os#el} != $os ]; then
  osname=RHEL
  osver=${os#el}
else
  echo "unknown OS ${os}"
  exit 0
fi

foreman_lookaside=""
if [ -n "${foreman_lookasides}" ]; then
  lookaside_repos=$(echo $foreman_lookasides | tr "," "\n")

  for lookaside_repo in $lookaside_repos
  do
      foreman_lookaside+="--repofrompath=${lookaside_repo},http://yum.theforeman.org/${lookaside_repo}/${os}/x86_64/ -l ${lookaside_repo} "
  done
fi

koji_lookaside=""
if [ -n "${koji_lookasides}" ]; then
  lookaside_repos=$(echo $koji_lookasides | tr "," "\n")

  for lookaside_repo in $lookaside_repos
  do
      koji_lookaside+="--repofrompath=${lookaside_repo},http://koji.katello.org/releases/yum/${lookaside_repo}/${osname}/${osver}/x86_64/ -l ${lookaside_repo} "
  done
fi

copr_lookaside=""
if [ -n "${copr_lookasides}" ]; then
  lookaside_repos=$(echo $copr_lookasides | tr "," "\n")

  for lookaside_repo in $lookaside_repos
  do
    copr_lookaside+="--repofrompath=${lookaside_repo},https://copr-be.cloud.fedoraproject.org/results/${lookaside_repo}/epel-${osver}-x86_64/ -l ${lookaside_repo} "
  done
fi

cd repoclosure
./repoclosure.sh yum_${os}.conf http://koji.katello.org/releases/yum/${repo}/${osname}/${osver}/x86_64/ -l ${os}-base -l ${os}-updates -l ${os}-epel -l ${os}-scl -l ${os}-scl-ruby -l ${os}-scl-v8 -l ${os}-openscap ${koji_lookaside} ${foreman_lookaside} ${copr_lookaside}
