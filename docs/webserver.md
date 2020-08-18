# Webserver

| | web02.rackspace.theforeman.org |
| - | - |
| type | OpenStack VM |
| OS | CentOS 7 |
| CPUs | 2 |
| RAM | 2GB |
| Storage | /dev/xvda (40GB): root, /dev/xvdb (100GB) + /dev/xvdc (50GB): data |
| Managed by | [web.pp](https://github.com/theforeman/foreman-infra/blob/master/puppet/modules/profiles/manifests/web.pp) |

## Domains

These domains are all hosted on the webserver.

* theforeman.org, www.theforeman.org
* deb.theforeman.org
* debugs.theforeman.org
* downloads.theforeman.org
* stagingdeb.theforeman.org
* yum.theforeman.org
* rsync.theforeman.org

### Fastly CDN

A Fastly CDN exists that sits in front of:

* downloads.theforeman.org
* stagingdeb.theforeman.org
* yum.theforeman.org

For these, the webserver acts as a backend while the content is served from the Fastly CDN to users.

## Volumes

/var/www is mounted on a separate 140GB block device via LVM.  /var/www/freight* contain the staging areas for freight (deb), and /var/www/vhosts contain the web roots themselves.

## Firewall

firewalld is manually configured (non-puppetized) with TCP ports:

* 22
* 80
* 443
* 873

## Other

* freight and freightstage users have private auto-signing GPG key imported manually (non-puppetized)
* In case of maintenance, a template page and config file snippet are under /var/www/503.  The config should be copied into each vhost.
