# Jenkins

The Foreman project maintains its own Jenkins instance for continuous integration at https://ci.theforeman.org/

It runs the following types of tests:

* Unit tests on the main develop and all supported stable branches of core Foreman projects
* Pull request tests against core Foreman projects
* Unit and pull request tests for many Foreman plugins
* Nightly and release package building and release processes
* Package smoke and integration testing
* Package jobs for Pulpcore

### CentOS QA service

CentOS offer access to their [QA CI infrastructure](https://wiki.centos.org/QaWiki/CI) to Foreman and other projects, which gives on-demand access to run tests on physical hardware running CentOS.  It consists of three main components:

* [ci.centos.org](https://ci.centos.org) - a Jenkins instance which we can manage jobs on
* foreman@slave01 - a user account on a slave which our jobs all run on
* [Duffy](https://wiki.centos.org/QaWiki/CI/Duffy) - on-demand provisioning of physical test servers running CentOS, available from foreman@slave01 jobs

Getting help:

* [centos-infra issues](https://pagure.io/centos-infra/issues)
* IRC: `#centos-ci` on `irc.libera.chat`

## Managing jobs

Jenkins itself is deployed onto one master VM from foreman-infra.  Jobs are maintained via Jenkins Job Builder - a set of YAML configuration files in foreman-infra that generate jobs. Jobs are kept in sync by an update job running inside of Jenkins. The update job itself (jenkins-jobs-update) is deployed via Puppet.

For detailed information see [Jenkins Job README](https://github.com/theforeman/jenkins-jobs/blob/master/README.md).

## Jenkins Nodes

### Configuration management

All nodes are maintained through our own Foreman instance using Puppet.  The Foreman instance has a host group called "Builders" and "Builders/Debian" which have the "slave" and other classes assigned to them. Debian machines have additional permissions to push Debian packages.

https://github.com/theforeman/foreman-infra/tree/master/puppet/modules contains the source for all Puppet modules.

### Node requirements

* CentOS 7
  * Clean, minimal base installation or the option to reinstall it
* 2GB of RAM per vCPU (4 vCPU + 8GB RAM is typical)
* 60GB disk (minimum), SSD preferred
* ~20GB/month bandwidth
* Public facing IP address
* Root access

### Configuring a new node

For Enterprise Linux:

* Ensure EPEL is configured: [epel-release](https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm)
* Ensure yum.pl.com is configured: [puppet6-release](https://yum.puppet.com/puppet6/puppet6-release-el-7.noarch.rpm)
* `yum -y install puppet-agent`
* `echo "server = puppetmaster.theforeman.org" >> /etc/puppetlabs/puppet/puppet.conf`
* ensure hostname is set node0X.jenkins.<provider>.theforeman.org where <provider> is osuosl or aws for example and that the record is in DNS
* Make the `puppet` command available: `source /etc/profile.d/puppet-agent.sh`
* `puppet ssl bootstrap`
* Sign the certificate on the puppetmaster or via Foreman
* `puppet agent --test`
* Set the host group to "Builders" in Foreman
* Run `puppet agent --test` twice (second run is important, due to the rvm module behaviour)


For Debian:

* Ensure apt.pl.com is configured: [puppet6-release](https://apt.puppetlabs.com/puppet6-release-buster.deb)
* `apt update && apt install puppet-agent`
* `echo "server = puppetmaster.theforeman.org" >> /etc/puppetlabs/puppet/puppet.conf`
* Make the `puppet` command available: `source /etc/profile.d/puppet-agent.sh`
* ensure hostname is set node0X.jenkins.<provider>.theforeman.org where <provider> is osuosl or aws for example and that the record is in DNS
* `puppet ssl bootstrap`
* Sign the certificate on the puppetmaster or via Foreman
* `puppet agent --test`
* Set the host group to "Builders/Debian" in Foreman
* Run `puppet agent --test` twice (second run is important, due to the rvm module behaviour)
