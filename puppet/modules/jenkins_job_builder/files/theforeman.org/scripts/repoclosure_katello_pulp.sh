#!/bin/bash -x

if [[ $foreman_version != 'nightly' ]]; then
  foreman_release_version=releases/${foreman_version}
else
  foreman_release_version=$foreman_version
fi

os=${os}
osver=${os#el}
repo=katello-${version}/pulp
koji_lookasides=katello-${version}/pulp,katello-${version}/candlepin
foreman_lookasides=plugins/${foreman_version},${foreman_release_version}
copr_lookasides=dgoodwin/subscription-manager
predefined_lookasides=extras

echo $os
if [ "${os}" = "el6" ]; then
  copr_lookasides="$copr_lookasides,@qpid/qpid"
fi

if [ $os == 'el7' ]; then
  copr_lookasides="$copr_lookasides,walters/rpm-ostree-dev"
fi

echo $copr_lookassides

puppet_lookasides=puppet3


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
      koji_lookaside+="--repofrompath=${lookaside_repo},http://koji.katello.org/releases/yum/${lookaside_repo}/${os}/x86_64/ -l ${lookaside_repo} "
  done
fi

echo "${copr_lookasides}"
copr_lookaside=""
if [ -n "${copr_lookasides}" ]; then
  lookaside_repos=$(echo $copr_lookasides | tr "," "\n")

  for lookaside_repo in $lookaside_repos
  do
    copr_lookaside+="--repofrompath=${lookaside_repo},https://copr-be.cloud.fedoraproject.org/results/${lookaside_repo}/epel-${osver}-x86_64/ -l ${lookaside_repo} "
  done
fi

puppet_lookaside=""
if [ -n "${puppet_lookasides}" -a ${os} != f24 ]; then
  lookaside_repos=$(echo $puppet_lookasides | tr "," "\n")

  for lookaside_repo in $lookaside_repos
  do
    if [ ${osname} == 'Fedora' ]; then
      puppet_lookaside+="--repofrompath=${lookaside_repo},http://yum.puppetlabs.com/fedora/${os}/products/x86_64/ -l ${lookaside_repo} --repofrompath=${lookaside_repo}-pc1,http://yum.puppetlabs.com/fedora/${os}/PC1/x86_64/ -l ${lookaside_repo}-pc1"
    else
      puppet_lookaside+="--repofrompath=${lookaside_repo},http://yum.puppetlabs.com/el/${osver}/products/x86_64/ -l ${lookaside_repo} --repofrompath=${lookaside_repo}-pc1,http://yum.puppetlabs.com/el/${osver}/PC1/x86_64/ -l ${lookaside_repo}-pc1"
    fi
  done
fi

predefined_lookaside=""
if [ -n "${predefined_lookasides}" ]; then
  lookaside_repos=$(echo $predefined_lookasides | tr "," "\n")

  for lookaside_repo in $lookaside_repos
  do
      predefined_lookaside+="-l ${os}-${lookaside_repo} "
  done
fi

options="yum_${os}.conf http://koji.katello.org/releases/yum/${repo}/${os}/x86_64/ -l ${os}-base -l ${os}-updates -l ${os}-epel -l ${os}-scl -l ${os}-scl-sclo -l ${os}-scl-ruby -l ${os}-scl-v8 ${koji_lookaside} ${foreman_lookaside} ${copr_lookaside} ${puppet_lookaside} ${predefined_lookaside}"

cd repoclosure

./repoclosure.sh $options
