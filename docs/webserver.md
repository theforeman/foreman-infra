# Webserver

| | website01.osuosl.theforeman.org |
| - | - |
| type | OpenStack VM |
| OS | CentOS Stream 9 |
| CPUs | 2 |
| RAM | 4GB |
| Storage | /dev/sda (30GB): root, /dev/sdb (30GB): data (LVM) |
| Managed by | [website.pp](https://github.com/theforeman/foreman-infra/blob/master/puppet/modules/profiles/manifests/website.pp) |

## Domains

These domains are all hosted on the webserver.

* theforeman.org, www.theforeman.org
* downloads.theforeman.org

### Fastly CDN

A Fastly CDN exists that sits in front of:

* theforeman.org, www.theforeman.org
* downloads.theforeman.org

For these, the webserver acts as a backend while the content is served from the Fastly CDN to users.

#### Configuration

The Fastly configuration happens through the `ansible/fastly.yml` Ansible playbook in this repository.

The major points of the configuration are:

* Set the backend to `<vhost>-backend.website01.osuosl.theforeman.org`
* Enable shielding: a central system fetches the assets and then distributes them across the CDN instead of each CDN node fetches them itself, this costs more CDN traffic, but is usually faster
* Configure a health-check and serve stale content when it fails

#### TLS

Fastly provides a shared certificate which has `theforeman.org` and `*.theforeman.org` as DNSAltName.

This certificate is signed by GlobalSign and we have a `_globalsign-domain-verification` TXT record in the `theforeman.org` DNS zone for verification of ownership.

#### DNS

Each vhost has a CNAME pointing at `dualstack.p2.shared.global.fastly.net` which is the Fastly global, dualstack loadbalancer.

Alternatively one can use `p2.shared.global.fastly.net` for an IPv4-only setup.

## Volumes

`/var/www` is mounted on a separate block device. `/var/www/vhosts` contains the web roots themselves.

## Firewall

There is no firewall on the machine itself. OpenStack has the following ports open:

* 22/tcp (SSH)
* 80/tcp (HTTP)
* 443/tcp (HTTPS)
