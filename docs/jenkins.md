# Jenkins

The Foreman project maintains its own Jenkins instance for continuous integration at https://ci.theforeman.org/

It runs the following types of tests:

* Unit tests on the main develop and all supported stable branches of core Foreman projects
* Pull request tests against core Foreman projects
* Unit and pull request tests for many Foreman plugins
* Nightly and release package building and release processes
* Package smoke and integration testing
* Package jobs for Pulpcore

## Quick reference for maintainers

Current PR test jobs (used on Foreman itself) support these commands:

* `ok to test` - run tests for an unknown user, if the code within the patch is not malicious
* `[test STATUS-NAME]`, e.g. `[test foreman]` to re-run a particular set of tests

## Quick reference for plugin maintainers

### Foreman plugin testing

Foreman plugins are tested by adding the plugin to a Foreman checkout and running core tests, so it checks that existing behaviours still work and new plugin tests are run too.  The [test_plugin_matrix job](https://ci.theforeman.org/job/test_plugin_matrix/) copies the core jobs, but adds a plugin from a given git repo/branch and is usually used to test plugins in a generic way.

Each plugin should have a job defined in JJB that calls test_plugin_matrix here: https://ci.theforeman.org/view/Plugins/

#### Foreman plugin PR testing

To test pull requests, a separate job is used that also takes the PR details: https://ci.theforeman.org/view/Plugins/job/test_plugin_pull_request/

#### Adding a new Foreman plugin

For a plugin "foreman_example", first create a job that tests the main (master or develop) branch.

* ensure plugin tests (if any) run when `rake jenkins:unit` is called, see [the example plugin](https://github.com/theforeman/foreman_plugin_template/) and [testing a plugin](https://projects.theforeman.org/projects/foreman/wiki/How_to_Create_a_Plugin#Testing) for help
* create a foreman_example.yaml file in [foreman-infra/JJB](https://github.com/theforeman/foreman-infra/tree/master/puppet/modules/jenkins_job_builder/files/theforeman.org/yaml/jobs/plugins)
  * This will create a "test_plugin_foreman_example_master" job in Jenkins to test the master branch.
* ensure the job is green by fixing bugs, installing dependencies etc.
* add hook to GitHub repo, see [GitHub repo hook](#testing-develop)

An org admin must then:

* add the repo to the [Bots team](https://github.com/orgs/theforeman/teams/bots/repositories) with **write** access

### Smart proxy plugin testing

Proxy plugins are tested like ordinary gems with tests run entirely from the plugin directory, installing the smart proxy as a dependency (via bundler's git support).  The [test_proxy_plugin_matrix job](https://ci.theforeman.org/job/test_proxy_plugin_matrix/) is usually used to test plugins in a generic way.

Each plugin should have a job defined in JJB that calls test_proxy_plugin_matrix here: https://ci.theforeman.org/view/Plugins/

#### Smart proxy plugin PR testing

To test pull requests, a separate job is used that also takes the PR details: https://ci.theforeman.org/view/Plugins/job/test_proxy_plugin_pull_request/

### Adding a new smart proxy plugin

For a plugin "smart_proxy_example", first create a job that tests the main (master or develop) branch.

* ensure plugin tests run when doing `bundle install` and `rake test`, see [testing a plugin](https://projects.theforeman.org/projects/foreman/wiki/How_to_Create_a_Smart-Proxy_Plugin#Testing) for help
* if different branches rely on different versions of smart proxy, specify `:branch` in Gemfile on those branches
* create a smart_proxy_example.yaml file in foreman-infra/JJB
* https://github.com/theforeman/foreman-infra/tree/master/puppet/modules/jenkins_job_builder/files/theforeman.org/yaml/jobs/plugins
* This will create a "test_proxy_plugin_smart_proxy_example_master" job in Jenkins to test the master branch.
* ensure the job is green by fixing bugs, installing dependencies etc.
* add hook to GitHub repo, see [GitHub repo hook](#testing-develop)

An org admin must then:

* add the repo to the [Bots team](https://github.com/orgs/theforeman/teams/bots/repositories) with **write** access

## Job configurations

### Testing develop

All repos with an associated job that tests their master/develop branch should have a hook added to the repo to trigger immediate builds.

To set up the hook, an org/repo admin must:

* View the repository settings
* Click *Webhooks*
* Click *Add webhook*
  * Payload URL: https://ci.theforeman.org/github-webhook/
  * Content Type: application/json (default)
  * Secret: add from secret store
  * Just the push event

### Pull request testing

Core Foreman projects have GitHub pull requests tested on our Jenkins instance so it's identical to the way we test the primary development branches themselves.  Simpler and quieter projects (such as installer modules) should use Travis CI which supports PR testing and reduces the load on our own infrastructure.

Every project that needs PR testing has at least two Jenkins jobs.  Taking core Foreman as an example:

* Test job for the main development branch (develop or master): [test_develop](https://ci.theforeman.org/job/test_develop/)
* Test job for each PR: [test_develop_pr_core](https://ci.theforeman.org/job/test_develop_pr_core/)

#### Github Pull Request Builder

The GHPRB plugin uses webhooks installed on the repo to trigger a build, then it runs any job configured with the GHPRB trigger and a matching GitHub project set.

The plugin tests the latest commit on the PR branch only, it does not merge the PR with the base branch. The webhook may also trigger multiple jobs, and jobs may use different GitHub commit status names to easily test and report status on different types of tests.

PR jobs should be set up identically to primary branch tests, except for the SCM (which checks out `${sha1}`) and to add the GHPRB trigger (see the `github_pr` macro in JJB).

To set up the hook, an org/repo admin goes to the repository settings, then Webhooks & Services and adds a webhook with these settings:

* Payload URL: `https://ci.theforeman.org/ghprbhook/`
* Content type: `application/json`
* Secret: _redacted_
* Events: _Let me select individual events_, _Pull request_, _Issue comment_

An org admin must then change the org teams:

* Add the repository to the [Bots team](https://github.com/orgs/theforeman/teams/bots/repositories) with **write** access

### CentOS QA service

CentOS offer access to their [QA CI infrastructure](https://wiki.centos.org/QaWiki/CI) to Foreman and other projects, which gives on-demand access to run tests on physical hardware running CentOS.  It consists of three main components:

* [ci.centos.org](https://ci.centos.org) - a Jenkins instance which we can manage jobs on
* foreman@slave01 - a user account on a slave which our jobs all run on
* [Duffy](https://wiki.centos.org/QaWiki/CI/Duffy) - on-demand provisioning of physical test servers running CentOS, available from foreman`slave01 jobs

## Managing jobs

Jenkins itself is deployed onto one master VM from foreman-infra.  Jobs are maintained via Jenkins Job Builder - a set of YAML configuration files in foreman-infra that generate jobs. Jobs are synced via Puppet and unmanaged jobs are purged daily.

### Jenkins Job Builder

[Jenkins Job Builder](https://docs.openstack.org/infra/jenkins-job-builder/) (JJB) is an OpenStack tool for generating Jenkins job definitions (an XML file) from a set of YAML job descriptions, which we store in version control.

* [JJB YAML files in foreman-infra](https://github.com/theforeman/foreman-infra/tree/master/puppet/modules/jenkins_job_builder/files)

Puppet deploys these onto our Jenkins server (a recursive file copy) and when they change, it runs the JJB tool to update the jobs in the live instance.  It also refreshes them daily to overwrite manual changes.

Useful resources:

* [Job definitions, templates etc.](https://docs.openstack.org/infra/jenkins-job-builder/definition.html)
* [Modules, e.g. SCM, publishers, builders](https://docs.openstack.org/infra/jenkins-job-builder/definition.html#modules)

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
