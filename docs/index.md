# Foreman Infrastructure

The Foreman project runs a number of different servers for testing, packaging, and continuous integration.
This infrastructure is maintained by the Infrastructure Special Interest Group (SIG).

Communication happens using [Discourse](https://community.theforeman.org/c/development/infra/24). It meets regularly and [posts meeting notes](https://community.theforeman.org/search?q=infrastructure%20sig%20meeting%20notes%20%23development%3Ainfra%20in%3Atitle%20order%3Alatest).

Issues are [tracked using GitHub](https://github.com/theforeman/foreman-infra/issues) and also visible [on a board](https://github.com/theforeman/foreman-infra/projects/1).

## Access

Access to Foreman project infrastructure is available for those who wish to assist in building packages, testing, and building Jenkins jobs.

Fork https://github.com/theforeman/foreman-infra and add your key into the [files directory](https://github.com/theforeman/foreman-infra/tree/master/puppet/modules/users/files) of the [`users` module](https://github.com/theforeman/foreman-infra/blob/master/puppet/modules/users/). Submit a pull request to the infrastructure project and send a post to the [Infra SIG discourse thread](https://community.theforeman.org/c/development/infra/24). One of them can merge your change and add your user in the Foreman web UI.

## Landscape

| Role | Provider(s) |
|---|---|
| [Discourse](discourse.md) | Conova |
| [Foreman](foreman.md) | Conova |
| [Koji](koji.md) | AWS |
| [Jenkins](jenkins.md) | Conova |
| [Jenkins Nodes](jenkins.md) | OSUOSL / AWS / Conova / Netways |
| [Puppet](puppet.md) | Conova |
| [Redmine](redmine.md) | Conova |
| [Virt](virt.md) | Conova |
| [Webserver](webserver.md) | OSUOSL |

## Infrastructure providers

A list of the hosting we have, who provides it, and what capacity it has

### Rackspace
  * Previously sponsored, now paid by Red Hat
  * Used for Mailgun to send email from Redmine and Discourse
  * Contact support from our account as needed
### Fastly
  * Sponsored
  * $1k/month CDN
  * Elaine Greenberg was initial contact
  * Support:
    * Ticket system: [https://support.fastly.com/](https://support.fastly.com/)
    * People with access: Evgeni, Ewoud
### OSUOSL
  * Sponsored
  * Hosts test machines, Jenkins nodes, and web01
  * Contact Lance Alberston if more capacity is needed
  * Support:
    * Contact: [https://osuosl.org/contact/](https://osuosl.org/contact/)
    * Ticket system: `support@osuosl.org`
    * IRC: `#osuosl` on `libera.chat`
### NETWAYS
  * Sponsored
  * Openstack instance for spinning up as needed compute
  * Option to add an Icinga Monitoring host here, talk to Dirk to progress
  * Support:
    * Ticket system: `nws@netways.de`
### Gandi
  * Sponsors theforeman.org domain
  * Support:
    * Ticket system: [https://help.gandi.net](https://help.gandi.net)
    * People with access: Evgeni, Ewoud
### CentOS
  * Sponsored
  * Provides Jenkins and bare metal hardware for running pipeline testing
  * Support:
    * IRC: `#centos-ci` on `libera.chat`
    * Ticket system: [https://pagure.io/centos-infra](https://pagure.io/centos-infra/issues)
### Conova
  * Sponsored
  * 1 HP Proliant machine (24 core, 192 GB RAM, 2×1TB SSD), incl power and network
  * Running libvirt and the following nodes on top of that: Foreman, Puppet, Redmine, Jenkins Controller, two Jenkins Nodes, Discourse
  * Support:
    * Ticket system: [https://ticket.conova.com/](https://ticket.conova.com/)
    * Talk to Evgeni
### OSCI.io
  * Sponsored
  * OpenShift access via https://openshift-console.osci.io/, needs RH Google account for sign in
  * Hosts prprocessor
  * Support:
    * Contact: [https://osci.io/](https://osci.io/)
    * IRC: `#openinfra` on `libera.chat`
