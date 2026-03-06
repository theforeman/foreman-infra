# Foreman

| | foreman01.conova.theforeman.org |
| - | - |
| type | Libvirt VM |
| OS | CentOS Stream 9 |
| CPUs | 4 |
| RAM | 4GB |
| Storage | /dev/vda (20GB) |
| Managed by | [profiles::foreman](https://github.com/theforeman/foreman-infra/blob/master/puppet/modules/profiles/manifests/foreman.pp) |

## Access

The Foreman UI is not accessible via the Internet, but you can use SSH forwarding to reach it.

Due to the limited number of IPv4 addresses we have at Conova, SSH is only available via IPv6.
The hypervisor (`virt01.conova.theforeman.org`) can be used as a jumphost, if you do not have native IPv6.

The following entry in `~/.ssh/config` configures both:

```
Host foreman01.conova.theforeman.org
  ProxyJump virt01.conova.theforeman.org # can be removed if you have IPv6
  LocalForward 9443 localhost:443
  ExitOnForwardFailure yes
```

After adding it, `ssh foreman01.conova.theforeman.org` will connect via `virt01` and forward `localhost:9443` on your system to the Foreman machine.

The Foreman UI (and API) is now accessible under `https://localhost:9443`.
