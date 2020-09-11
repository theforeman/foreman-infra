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

#### Configuration

The Fastly configuration happens through the `ansible/fastly.yml` Ansible playbook in this repository.

The major points of the configuration are:

* Set the backend to `web02.theforeman.org`
* Enable shielding: a central system fetches the assets and then distributes them across the CDN instead of each CDN node fetches them itself, this costs more CDN traffic, but less traffic for web02 which is more expensive
* Configure a health-check and serve stale content when it fails
* Log requests to a RackSpace CloudFiles (S3-like) bucket

#### TLS

Fastly provides a shared certificate which has `theforeman.org` and `*.theforeman.org` as DNSAltName.

This certificate is signed by GlobalSign and we have a `_globalsign-domain-verification` TXT record in the `theforeman.org` DNS zone for verification of ownership.

#### DNS

Each vhost has a CNAME pointing at `dualstack.p2.shared.global.fastly.net` which is the Fastly global, dualstack loadbalancer.

Alternatively one can use `p2.shared.global.fastly.net` for an IPv4-only setup.

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
