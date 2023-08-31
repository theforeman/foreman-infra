# Virtualization host

| | virt01.conova.theforeman.org |
|-|-|
| type | HPE ProLiant DL325 Gen10 |
| OS | CentOS Stream 8 |
| CPUs | AMD EPYC 7402P 24-Core Processor |
| RAM | 64GB |
| Storage | 2 * 1TB SSD NVMe |

## Installation

Set up networking:

```
nmcli connection add type bridge con-name "Bridge connection 1" ifname br0
nmcli connection modify bridge0 ipv4.addresses '195.192.212.25/29'
nmcli connection modify bridge0 ipv4.gateway '195.192.212.30'
nmcli connection modify bridge0 ipv4.dns '217.196.144.129'
nmcli connection modify bridge0 ipv4.dns-search 'conova.theforeman.org'
nmcli connection modify bridge0 ipv4.method manual
nmcli connection modify bridge0 ipv6.method auto
nmcli connection add type bond con-name Bond connection 1" ifname bond0 bond.options "mode=802.3ad,downdelay=0,miimon=1,updelay=0" ipv4.method disabled ipv6.method ignore master "Bridge connection 1"
nmcli connection add type ethernet ifname eno5np0 master bond0
nmcli connection add type ethernet ifname eno6np1 master bond0
nmcli connection up bridge0
```

Note the options were derived after the fact. They may not be 100% correct. See [RHEL 8 networking documentation](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/configuring_and_managing_networking/configuring-a-network-bridge_configuring-and-managing-networking) for more.

Now install libvirt:

```
dnf group install 'Virtualization Host'
sed -i '/unix_sock_group/ s/^#//' /etc/libvirt/libvirtd.conf
systemctl enable --now libvirtd
```

Now bootstrap Puppet:
```
dnf install https://yum.puppet.com/puppet7-release-el-8.noarch.rpm
dnf install puppet-agent
. /etc/profile.d/puppet-agent.sh
puppet config set server puppetmaster.theforeman.org
puppet ssl bootstrap
puppet agent -t
```

