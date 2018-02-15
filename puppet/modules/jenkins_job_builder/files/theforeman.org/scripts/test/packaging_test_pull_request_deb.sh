#!/bin/bash -ex

### Debian builds
[ ${branch##deb/} = $branch ] && exit 0

mkdir -p test_builds/{debian,dependencies,plugins,smart_proxy_plugins,katello}

# deb build jobs assume a deb/ branch prefix
pr_git_short_ref=${pr_git_ref##deb/}

# deb build jobs assume GitHub user names
pr_git_username=${pr_git_url##git://github.com/}
pr_git_username=${pr_git_username%%/foreman-packaging.git}

# deb component
branch_version=${branch##deb/}
[ x$branch_version = xdevelop ] && branch_version=nightly

# identify changed core projects, 5 at most!
for p in $(git diff --name-only pr/${pr_git_ref} $(git merge-base pr/${pr_git_ref} upstream/${branch}) debian | cut -d/ -f3 | sort -u | tail -n5); do
  [ $(find debian/*/${p} -name control | wc -l) -ge 1 ] || continue

  cat > test_builds/debian/${p}.properties <<EOF
project=${p}
repoowner=${pr_git_username}
repo=${pr_git_short_ref}
version=${branch_version}
EOF

  [ $p = foreman ] && echo "nightly_jenkins_job=test_develop" >> test_builds/debian/${p}.properties || true
  [ $p = foreman-proxy ] && echo "nightly_jenkins_job=test_proxy_develop" >> test_builds/debian/${p}.properties || true
  [ $p = foreman-selinux ] && echo "nightly_jenkins_job=packaging_trigger_selinux_develop" >> test_builds/debian/${p}.properties || true
  [ $p = foreman-installer ] && echo "nightly_jenkins_job=packaging_trigger_installer_develop" >> test_builds/debian/${p}.properties || true
done

# identify changed dependencies, 5 at most!
for p in $(git diff --name-only pr/${pr_git_ref} $(git merge-base pr/${pr_git_ref} upstream/${branch}) dependencies | cut -d/ -f3 | sort -u | tail -n5); do
  [ $(find dependencies/*/${p} -name control | wc -l) -ge 1 ] || continue

  cat > test_builds/dependencies/${p}.properties <<EOF
project=${p}
repoowner=${pr_git_username}
repo=${pr_git_short_ref}
version=${branch_version}
EOF
done

# identify changed plugins, 5 at most!
for p in $(git diff --name-only pr/${pr_git_ref} $(git merge-base pr/${pr_git_ref} upstream/${branch}) plugins | cut -d/ -f2 | sort -u | tail -n5); do
  [ $(find plugins/${p} -name control | wc -l) -ge 1 ] || continue
  [[ ${p} =~ ^smart_proxy_ ]] && continue

  cat > test_builds/plugins/${p}.properties <<EOF
project=${p}
repoowner=${pr_git_username}
repo=${pr_git_short_ref}
version=${branch_version}
EOF
done


# identify changed smart proxy plugins, 5 at most!
for p in $(git diff --name-only pr/${pr_git_ref} $(git merge-base pr/${pr_git_ref} upstream/${branch}) plugins | cut -d/ -f2 | sort -u | tail -n5); do
  [ $(find plugins/${p} -name control | wc -l) -ge 1 ] || continue
  [[ ${p} =~ ^smart_proxy_ ]] || continue

  cat > test_builds/smart_proxy_plugins/${p}.properties <<EOF
project=${p}
repoowner=${pr_git_username}
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
