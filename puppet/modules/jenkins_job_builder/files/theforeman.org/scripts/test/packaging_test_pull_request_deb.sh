#!/bin/bash -ex

### Debian builds
[[ $ghprbTargetBranch == deb/* ]] || exit 0

if [[ $ghprbSourceBranch != deb/* ]] ; then
  echo "Source branch name must start with deb/"
  exit 1
fi

mkdir -p test_builds/{debian,dependencies,plugins,smart_proxy_plugins,katello}

# deb build jobs assume a deb/ branch prefix
pr_git_short_ref=${ghprbSourceBranch##deb/}

# deb component
branch_version=${ghprbTargetBranch##deb/}
[ x$branch_version = xdevelop ] && branch_version=nightly

merge_base=$(git merge-base HEAD upstream/${ghprbTargetBranch})

# identify changed core projects, 5 at most!
for p in $(git diff --name-only HEAD $merge_base debian | cut -d/ -f3 | sort -u | tail -n5); do
  [ $(find debian/*/${p} -name control | wc -l) -ge 1 ] || continue

  cat > test_builds/debian/${p}.properties <<EOF
project=${p}
repoowner=${ghprbPullAuthorLogin}
repo=${pr_git_short_ref}
version=${branch_version}
EOF

  if [[ $p == foreman-proxy ]] ; then
    echo "nightly_jenkins_job=smart-proxy-develop-source-release" >> test_builds/debian/${p}.properties
  elif [[ $p == foreman* ]] ; then
    echo "nightly_jenkins_job=$p-develop-source-release" >> test_builds/debian/${p}.properties
  fi
done

# identify changed dependencies, 5 at most!
for p in $(git diff --name-only HEAD $merge_base dependencies | cut -d/ -f3 | sort -u | tail -n5); do
  [ $(find dependencies/*/${p} -name control | wc -l) -ge 1 ] || continue

  cat > test_builds/dependencies/${p}.properties <<EOF
project=${p}
repoowner=${ghprbPullAuthorLogin}
repo=${pr_git_short_ref}
version=${branch_version}
EOF
done

# identify changed plugins, 5 at most!
for p in $(git diff --name-only HEAD $merge_base plugins | cut -d/ -f2 | sort -u | tail -n5); do
  [ $(find plugins/${p} -name control | wc -l) -ge 1 ] || continue
  [[ ${p} =~ ^smart_proxy_ ]] && continue

  cat > test_builds/plugins/${p}.properties <<EOF
project=${p}
repoowner=${ghprbPullAuthorLogin}
repo=${pr_git_short_ref}
version=${branch_version}
EOF
done


# identify changed smart proxy plugins, 5 at most!
for p in $(git diff --name-only HEAD $merge_base plugins | cut -d/ -f2 | sort -u | tail -n5); do
  [ $(find plugins/${p} -name control | wc -l) -ge 1 ] || continue
  [[ ${p} =~ ^smart_proxy_ ]] || continue

  cat > test_builds/smart_proxy_plugins/${p}.properties <<EOF
project=${p}
repoowner=${ghprbPullAuthorLogin}
repo=${pr_git_short_ref}
EOF
done

set +x
for f in $(find test_builds -type f -name *.properties); do
  echo
  echo "===== $f ====="
  cat $f
  echo
done
