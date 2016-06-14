#!/bin/bash -ex

if [ -n "${pr_git_url}" -a ${scratch} != true ]; then
  echo "ERROR: scratch must be true for PR builds"
  exit 1
fi

git-annex init
./setup_sources.sh $project

mkdir rel-eng/build
args="-o $(pwd)/rel-eng/build/"
[ -n "${tag}" ] && args="$args --tag=$tag"
[ x"${scratch}" != xfalse ] && args="$args --scratch"
[ x"${gitrelease}" != xfalse -a x${releaser} != xkoji-foreman-nightly ] && args="$args --test"
[ -n "${nightly_jenkins_job}" ] && args="$args --arg jenkins_job=${nightly_jenkins_job}"
[ -n "${nightly_jenkins_job_id}" ] && args="$args --arg jenkins_job_id=${nightly_jenkins_job_id}"

cd $project
tito release ${args} ${releaser} 2>&1 | tee tito.log

if [ ${PIPESTATUS[0]} -ne 0 ]; then
  echo "tito release failed, exit code ${PIPESTATUS[0]}"
  exit 1
fi

grep "Task info:" tito.log | grep -o "[0-9]*" > tasks || true

if [ -s tasks ]; then
  xargs koji -c ~/.koji/katello-config watch-task < tasks
fi
