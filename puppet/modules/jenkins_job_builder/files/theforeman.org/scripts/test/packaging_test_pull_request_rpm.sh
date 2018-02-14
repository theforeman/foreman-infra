#!/bin/bash -ex

### RPM builds
[ ${branch##rpm/} = $branch ] && exit 0


# identify changed projects, 5 at most!
git --version

if [ -d packages ];then
  to_build=$(git diff --name-only $(git merge-base upstream/${branch} pr/${pr_git_ref}) pr/${pr_git_ref} | grep spec | grep packages | tail -n15)
else
  to_build=$(git diff --name-only $(git merge-base upstream/${branch} pr/${pr_git_ref}) pr/${pr_git_ref} | grep spec | tail -n15)
fi

echo $to_build

for p in $to_build; do
  echo ${p}

  project=$(dirname $p)
  subdir=$(basename $(dirname $project))
  p=$(basename $p)
  p=${p/.spec}
  mkdir -p test_builds/rpm/${p}

  if [ $branch = "rpm/develop" ]; then
    case "$p" in
      foreman)
        echo "nightly_jenkins_job=test_develop" >> test_builds/rpm/${p}.properties
        r=koji-foreman-nightly
        ;;
      foreman-proxy)
        echo "nightly_jenkins_job=test_proxy_develop" >> test_builds/rpm/${p}.properties
        r=koji-foreman-nightly
        ;;
      foreman-selinux)
        echo "nightly_jenkins_job=packaging_trigger_selinux_develop" >> test_builds/rpm/${p}.properties
        r=koji-foreman-nightly
        ;;
      foreman-installer)
        echo "nightly_jenkins_job=packaging_trigger_installer_develop" >> test_builds/rpm/${p}.properties
        r=koji-foreman-nightly
        ;;
      rubygem-katello)
        echo "nightly_jenkins_job=test_katello_core" >> test_builds/rpm/${p}.properties
        echo "gitrelease=false" >> test_builds/rpm/${p}.properties
        r=koji-katello-jenkins
        ;;
      katello-installer)
        echo "nightly_jenkins_job=release_build_katello_installer" >> test_builds/rpm/${p}.properties
        r=koji-katello-jenkins
        echo "gitrelease=false" >> test_builds/rpm/${p}.properties
        ;;
      *)
        if [[ -d projects ]] ; then
          echo "gitrelease=true" >> test_builds/rpm/${p}.properties
          if [[ $subdir == "katello" ]] ; then
            r=koji-katello
          elif [[ $subdir == "plugins" ]] ; then
            r=koji-foreman-plugins
          else
            r=koji-foreman
          fi
        else
          r=""
        fi
        ;;
    esac
  fi

  if [[ -d projects ]] ; then
    echo "project=${project}" >> test_builds/rpm/${p}.properties
    echo "releaser=${r}" >> test_builds/rpm/${p}.properties

    if [[ $subdir == "katello" ]] ; then
      mv test_builds/rpm/${p}.properties test_builds/rpm/${p}-katello.properties
      echo "releaser=koji-katello-client" >> test_builds/rpm/${p}-katello.properties
    elif [[ $subdir == "plugins" ]] ; then
      mv test_builds/rpm/${p}.properties test_builds/rpm/${p}-plugins.properties
    fi
  else
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
  fi
done
