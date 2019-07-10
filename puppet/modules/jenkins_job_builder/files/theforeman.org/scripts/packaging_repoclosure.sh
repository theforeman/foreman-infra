#!/bin/bash -e


if [ ${os#centos} != $os ]; then
  os=el${os#centos}
fi

if [ ${os#el} != $os ]; then
  osname=RHEL
  osver=${os#el}
else
  echo "unknown OS ${os}"
  exit 0
fi

foreman_lookaside=""
foreman_lookasides="${foreman_lookasides} rails/${repo}"
if [ -n "${foreman_lookasides}" ]; then
  lookaside_repos=$(echo $foreman_lookasides | tr "," "\n")

  for lookaside_repo in $lookaside_repos
  do
      foreman_lookaside+="--repofrompath=${lookaside_repo},https://yum.theforeman.org/${lookaside_repo}/${os}/x86_64/ -l ${lookaside_repo} "
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

predefined_lookaside=""
predefined_lookasides="${predefined_lookasides} base updates extras epel scl puppet-6 puppet-5"
if [[ -n $predefined_lookasides ]]; then
  lookaside_repos=$(echo $predefined_lookasides | tr "," "\n")

  for lookaside_repo in $lookaside_repos
  do
      predefined_lookaside+="-l ${os}-${lookaside_repo} "
  done
fi

options="yum_${os}.conf http://koji.katello.org/releases/yum/${repo}/${osname}/${osver}/x86_64/ ${koji_lookaside} ${foreman_lookaside} ${copr_lookaside} ${puppet_lookaside} ${predefined_lookaside}"

if [[ $1 == '--dry-run' ]]; then
  echo $options
else
  cd repoclosure
  ./repoclosure.sh $options
fi
