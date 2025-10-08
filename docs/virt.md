# Virtualization host

| | virt01.conova.theforeman.org |
|-|-|
| type | HPE ProLiant DL325 Gen10 |
| OS | CentOS Stream 9 |
| CPUs | AMD EPYC 7402P 24-Core Processor |
| RAM | 192GB |
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
dnf install https://yum.voxpupuli.org/openvox8-release-el-9.noarch.rpm
dnf install openvox-agent
. /etc/profile.d/puppet-agent.sh
puppet config set server puppet.theforeman.org
puppet ssl bootstrap
puppet agent -t
```

## Storage

The system has 2 1TB NVMe drives, which are configured as individual drives, not as RAID in the HP firmware.

The OS and the virt guests are residing on LVM, with select LVs in RAID1 mode.

### converting an existing LV to RAID1

```
lvconvert --type raid1 -m 1 cs_node01/<lvname>
```

See [Converting a Linear device to a RAID logical volume](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/configuring_and_managing_logical_volumes/configuring-raid-logical-volumes_configuring-and-managing-logical-volumes#converting-a-linear-device-to-a-raid-logical-volume_configuring-raid-logical-volumes).
