#!/bin/bash -xe

# Reset environment
rm -rf public/
git checkout deploy
git reset origin/deploy --hard

./deploy.rb
if ! git remote | grep openshift > /dev/null; then
  git remote add openshift ssh://53fe3c0b5973ca67f1000266@site-katelloproject.rhcloud.com/~/git/site.git/
fi

git add public/
git commit -a -m 'Deploying build'

# Create GIT_SSH script so that we can push using the deploy key
cat > git_ssh.sh <<EOL
#!/bin/sh
ssh -i /var/lib/workspace/workspace/deploy_katello_repos_key/deploy_katello_repos_key "\$@"
EOL
chmod 777 git_ssh.sh

git branch
GIT_SSH=./git_ssh.sh git push openshift deploy:master --force
