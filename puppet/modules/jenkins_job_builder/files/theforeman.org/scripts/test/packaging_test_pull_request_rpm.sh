#!/bin/bash -ex

### RPM builds
[[ $ghprbTargetBranch == rpm/* ]] || exit 0

git --version

merge_base=$(git merge-base HEAD upstream/${ghprbTargetBranch})

# identify changed projects, 15 at most!
to_build=$(git diff --name-only $merge_base HEAD | grep spec | tail -n15)

echo $to_build

for p in $to_build; do
  echo ${p}

  project=$(dirname $p)
  subdir=$(basename $(dirname $project))
  p=$(basename $p)
  p=${p/.spec}
  mkdir -p test_builds/rpm/${p}

  if [[ $project == *"katello"* && -z "$r" ]]; then
    echo "project=${project}" >> test_builds/rpm/${p}.properties
    mv test_builds/rpm/${p}.properties test_builds/rpm/${p}-katello.properties
    echo "releaser=koji-katello" >> test_builds/rpm/${p}-katello.properties
    echo "releaser=koji-katello-client" >> test_builds/rpm/${p}-katello.properties
    echo "gitrelease=true" >> test_builds/rpm/${p}-katello.properties
  elif [ -z "$r" ]; then
    # build once for main releaser, once for plugins (one or both may be no-ops)
    echo "project=${project}" >> test_builds/rpm/${p}.properties
    cp test_builds/rpm/${p}.properties test_builds/rpm/${p}-plugins.properties
    cp test_builds/rpm/${p}.properties test_builds/rpm/${p}-katello.properties
    echo "releaser=koji-foreman" >> test_builds/rpm/${p}.properties
    echo "releaser=koji-foreman-plugins" >> test_builds/rpm/${p}-plugins.properties
    echo "gitrelease=true" >> test_builds/rpm/${p}.properties
    echo "gitrelease=true" >> test_builds/rpm/${p}-plugins.properties
  else
    echo "project=${project}" >> test_builds/rpm/${p}.properties
    echo "releaser=${r}" >> test_builds/rpm/${p}.properties
  fi
done
