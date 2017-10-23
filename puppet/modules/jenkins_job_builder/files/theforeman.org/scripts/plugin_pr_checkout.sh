#!/bin/bash -xe

pushd plugin

if [ -n "${pr_git_url}" ]; then
  git remote add pr ${pr_git_url}
  git fetch pr
  git merge pr/${pr_git_ref}
fi

popd
