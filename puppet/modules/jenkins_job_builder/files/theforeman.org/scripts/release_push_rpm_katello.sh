#!/bin/bash -xe

ssh -i /var/lib/workspace/workspace/deploy_katello_repos_key/deploy_katello_repos_key katelloproject@fedorapeople.org "cd /project/katello/bin && sh rsync-repos-from-koji $RELEASE"
