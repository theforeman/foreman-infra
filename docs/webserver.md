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

### CDN

The user traffic is served the [CDN](cdn.md), the webserver acts as a backend.

## Volumes

`/var/www` is mounted on a separate block device. `/var/www/vhosts` contains the web roots themselves.

## Firewall

There is no firewall on the machine itself. OpenStack has the following ports open:

* 22/tcp (SSH)
* 80/tcp (HTTP)
* 443/tcp (HTTPS)
