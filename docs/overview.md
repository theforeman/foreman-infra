# Overview

The Foreman project runs a number of different servers for testing, packaging, and continuous integration.

## Access

Access to Foreman project infrastructure is available for those who wish to assist in building packages, testing, and building Jenkins jobs.

Fork https://github.com/theforeman/foreman-infra and add your key into the [files directory](https://github.com/theforeman/foreman-infra/tree/master/puppet/modules/users/files) of the [`users` module](https://github.com/theforeman/foreman-infra/blob/master/puppet/modules/users/). Submit a pull request to the infrastructure project and send a post to the [Infra SIG discourse thread](https://community.theforeman.org/c/development/infra/24). One of them can merge your change and add your user in the Foreman web UI.

## Landscape

| Role | Provider(s) |
|---|---|
| [Jenkins](./docs/jenkins.md) | OSUOSL |
| [Koji](./docs/koji.md) | AWS |
| [Jenkins Nodes](./docs/jenkins.md)  | OSUOSL / AWS / Conova |

## Infrastructure providers

A list of the hosting we have, who provides it, and what capacity it has

* Rackspace
  * Previously sponsored, [being phased out](https://community.theforeman.org/t/rfc-moving-off-of-rackspace-infrastructure/17932)
  * Hosts Jenkins
  * Contact support from our account as needed
* Scaleway
  * Previously sponsored, planned to be phased out
  * Support usually helpful, Edouard Bonlieu & Yann Léger were initial contacts
  * Hosts Discourse, Redmine, ARM Jenkins nodes
* Fastly
  * Sponsored
  * $1k/month CDN
  * Elaine Greenberg was initial contact
* OSUOSL
  * Sponsored
  * Hosts test machines, Jenkins nodes, and web01
  * Contact Lance Alberston if more capacity is needed
* NETWAYS
  * Sponsored
  * Openstack instance for spinning up as needed compute
  * Option to add an Icinga Monitoring host here, talk to Dirk to progress
* Gandi
  * Sponsors theforeman.org domain
* Individual contributors
  * Variety of single VMs, see the Foreman Dashboard for details
* CentOS
  * Sponsored
  * Provides Jenkins and bare metal hardware for running pipeline testing
* Conova
  * Sponsored
  * 1 HP Proliant machine (24 core, 64 GB RAM, 2×1TB SSD), incl power and network
  * Running libvirt and two Jenkins nodes on top of that
