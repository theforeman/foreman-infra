# Webserver

| | web01.osuosl.theforeman.org |
| - | - |
| type | OpenStack VM |
| OS | CentOS 7 |
| CPUs | 2 |
| RAM | 4GB |
| Storage | /dev/sda (30GB): root, /dev/sdb (150GB): data (LVM), /dev/sdc (50G): data (LVM) |
| Managed by | [web.pp](https://github.com/theforeman/foreman-infra/blob/master/puppet/modules/profiles/manifests/web.pp) |

## Domains

These domains are all hosted on the webserver.

* theforeman.org, www.theforeman.org
* deb.theforeman.org
* debugs.theforeman.org
* downloads.theforeman.org
* stagingdeb.theforeman.org
* yum.theforeman.org
* stagingyum.theforeman.org
* rsync.theforeman.org

### Fastly CDN

A Fastly CDN exists that sits in front of:

* deb.theforeman.org
* downloads.theforeman.org
* stagingdeb.theforeman.org
* yum.theforeman.org
* stagingyum.theforeman.org

For these, the webserver acts as a backend while the content is served from the Fastly CDN to users.

#### Configuration

The Fastly configuration happens through the `ansible/fastly.yml` Ansible playbook in this repository.

The major points of the configuration are:

* Set the backend to `web02.theforeman.org`
* Enable shielding: a central system fetches the assets and then distributes them across the CDN instead of each CDN node fetches them itself, this costs more CDN traffic, but less traffic for web02 which is more expensive
* Configure a health-check and serve stale content when it fails

#### TLS

Fastly provides a shared certificate which has `theforeman.org` and `*.theforeman.org` as DNSAltName.

This certificate is signed by GlobalSign and we have a `_globalsign-domain-verification` TXT record in the `theforeman.org` DNS zone for verification of ownership.

#### DNS

Each vhost has a CNAME pointing at `dualstack.p2.shared.global.fastly.net` which is the Fastly global, dualstack loadbalancer.

Alternatively one can use `p2.shared.global.fastly.net` for an IPv4-only setup.

## Volumes

/var/www is mounted on a separate 140GB block device.  /var/www/freight* contain the staging areas for freight (deb), and /var/www/vhosts contain the web roots themselves.

## Firewall

There is no firewall on the machine itself. OpenStack has the following ports open:

* 22/tcp (SSH)
* 80/tcp (HTTP)
* 443/tcp (HTTPS)
* 873/tcp, 873/udp (rsync)

## Other

* freight and freightstage users have private auto-signing GPG key imported manually (non-puppetized)
* In case of maintenance, a template page and config file snippet are under /var/www/503.  The config should be copied into each vhost.
