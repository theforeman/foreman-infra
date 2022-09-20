# Boostrap a new environment

To rebuild the whole Foreman Infrastructure from scratch, these are the steps to get started.

## Build a Puppetserver

Install a minimal EL8 install. Then:

```sh
dnf install https://yum.puppet.com/puppet7-release-el-8.noarch.rpm
dnf install puppetserver
. /etc/profile.d/puppet-agent.sh
puppetserver ca setup --ca-name 'Foreman Puppet CA' --certname $HOSTNAME --subject-alt-names puppet.theforeman.org
puppet config set --section agent server puppet.theforeman.org
puppet config set --section main dns_alt_names puppet.theforeman.org
# To allow the foreman node a SAN
sed -i '/allow-subject-alt-names/ s/false/true/' /etc/puppetlabs/puppetserver/conf.d/ca.conf
systemctl enable --now puppetserver puppet
firewall-cmd --add-port 8140/tcp
firewall-cmd --add-port 8140/tcp --permanent
mkdir /etc/puppetlabs/code/environments/bootstrap
chown YOURUSER: /etc/puppetlabs/code/environments/bootstrap
```

With a basic Puppetserver running, deploy the environment. From your local machine:

```
# Download the latest from https://github.com/xorpaul/g10k/releases and place it in ~/bin
git clone https://github.com/theforeman/foreman-infra
cd foreman-infra/puppet
g10k -cachedir ~/.cache/.g10k -puppetfile
rsync -av --delete --exclude={Gem,Rake,Puppet}file*,test_modules,spec,check_dependencies ./ SERVER.EXAMPLE.COM:/etc/puppetlabs/code/environments/bootstrap/
```

## Build a Foreman server

Install a minimal EL8 install. Then:

```sh
dnf install https://yum.puppet.com/puppet7-release-el-8.noarch.rpm
dnf install puppet-agent
. /etc/profile.d/puppet-agent.sh
puppet config set --section agent environment bootstrap
puppet config set --section agent server puppet.theforeman.org
puppet config set --section main dns_alt_names foreman.theforeman.org
puppet ssl bootstrap
systemctl enable --now puppet
```

In case it should become a production setup, import the database dump:
```
puppet agent --disable
systemctl stop foreman\* dynflow\*
sudo -u postgres dropdb foreman
sudo -u postgres createdb -O foreman foreman
sudo -u postgres psql foreman < /path/to/dump.sql
foreman-rake db:migrate
foreman-rake db:seed
puppet agent --enable
puppet agent -t
```
