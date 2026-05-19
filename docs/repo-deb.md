# DEB repository server

| | repo-deb01.osuosl.theforeman.org |
| - | - |
| type | OpenStack VM |
| OS | CentOS Stream 9 |
| CPUs | 2 |
| RAM | 4GB |
| Storage | /dev/sda (30GB): root, /dev/sdb (150GB): data (LVM) |
| Managed by | [deb.pp](https://github.com/theforeman/foreman-infra/blob/master/puppet/modules/profiles/manifests/repo/deb.pp) |

## Domains

These domains are all hosted on the server.

* deb.theforeman.org
* stagingdeb.theforeman.org
* archivedeb.theforeman.org

### Backends

This server does not host the domains directly, but has the following backend vhosts configured:

* deb-backend.repo-deb01.osuosl.theforeman.org
* stagingdeb-backend.repo-deb01.osuosl.theforeman.org
* archivedeb-backend.repo-deb01.osuosl.theforeman.org

#### TLS

The backends have TLS certificates from Let's Encrypt, using the HTTP challenge.

This allows the frontend to talk securely to the backends.

### CDN

The frontend is served by the [CDN](cdn.md).

## Volumes

`/var/www` is mounted on a separate block device. `/var/www/freight*` contains the staging areas for freight (deb), and `/var/www/vhosts` contains the web roots themselves.

## Firewall

There is no firewall on the machine itself. OpenStack has the following ports open:

* 22/tcp (SSH)
* 80/tcp (HTTP)
* 443/tcp (HTTPS)

## Other

* freight and freightstage users have private auto-signing GPG key imported manually (non-puppetized)
