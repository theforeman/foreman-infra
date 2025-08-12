# Puppetserver

The puppetserver is hosted on `puppet.theforeman.org`, which is a CNAME to the actual server.
On the actual server a subjectAltName is configured so both the hostname and service name should work.

| | puppet01.conova.theforeman.org |
| - | - |
| type | Libvirt VM |
| OS | CentOS Stream 9 |
| CPUs | 4 |
| RAM | 8GB |
| Storage | /dev/vda (20GB) |
| Managed by | [profiles::puppetserver](https://github.com/theforeman/foreman-infra/blob/master/puppet/modules/profiles/manifests/puppetserver.pp) |
