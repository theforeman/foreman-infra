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

### Fastly CDN

The frontend is served by the Fastly CDN.

The configuration happens through the `ansible/fastly.yml` Ansible playbook in this repository.

The major points of the configuration are:

* Set the backend to `<vhost>-backend.repo-deb01.osuosl.theforeman.org`
* Enable shielding: a central system fetches the assets and then distributes them across the CDN instead of each CDN node fetches them itself, this costs more CDN traffic, but is usually faster
* Configure a health-check and serve stale content when it fails

#### TLS

Fastly provides a shared certificate which has `theforeman.org` and `*.theforeman.org` as DNSAltName.

This certificate is signed by GlobalSign and we have a `_globalsign-domain-verification` TXT record in the `theforeman.org` DNS zone for verification of ownership.

#### DNS

Each vhost has a CNAME pointing at `dualstack.p2.shared.global.fastly.net` which is the Fastly global, dualstack loadbalancer.

Alternatively one can use `p2.shared.global.fastly.net` for an IPv4-only setup.

## Volumes

`/var/www` is mounted on a separate block device. `/var/www/freight*` contains the staging areas for freight (deb), and `/var/www/vhosts` contains the web roots themselves.

## Firewall

There is no firewall on the machine itself. OpenStack has the following ports open:

* 22/tcp (SSH)
* 80/tcp (HTTP)
* 443/tcp (HTTPS)

## Other

* freight and freightstage users have private auto-signing GPG key imported manually (non-puppetized)
