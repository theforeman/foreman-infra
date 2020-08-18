# Koji

[Koji](https://pagure.io/koji/) is an RPM build and tracking system. The Foreman project Koji instance lives at [Foreman Koji](http://koji.katello.org/koji/).

| | koji.katello.org |
| type | AWS EC2 us-east-1 |
| flavor | i3.xlarge |
| OS | CentOS 7 from 8 GB EBS volume |
| CPUs | 4 |
| RAM | 32GB |
| Storage | 900 GB SSD NVMe |

### Volumes and mounts

* /dev/xvda1 - root
* /dev/xvdx1 - /mnt/koji (1TB)
* /dev/nvme0n1 - swap and /mnt/tmp

Root EBS volume is mounted via UUID in fstab:

```console
UUID=29342a0b-e20f-4676-9ecf-dfdf02ef6683 / xfs defaults 0 0
```

Note that other volumes are not present in fstab, this is to prevent booting into emergency mode when the VM is respinned on a different hypervisor with different or empty ephemeral or EBS storage configuration. All the rest is mounted in /etc/rc.local:

```console
swapon /dev/nvme0n1p1
mount /dev/nvme0n1p2 /mnt/tmp -o defaults,noatime,nodiratime
mount /dev/xvdx1 /mnt/koji -o defaults,noatime,nodiratime
hostnamectl set-hostname koji.katello.org
systemctl restart pmcd pmlogger pmwebd
mount | grep /mnt/koji && systemctl restart rsyncd
mount | grep /mnt/koji && systemctl start postgresql
systemctl start httpd
mount | grep /mnt/koji && mount | grep /mnt/tmp && systemctl start kojid kojira
```

On our current VM flavour there is a local SSD NVMe storage (/dev/nvme0n1) with two partitions created (50/50). The first one is swap and the second one is mounted as /mnt/tmp where koji does all the work. This volume needs to be fast, it grows over the time and contains temporary files (built packages, build logs, support files).

The main data directory containing the PostgreSQL database and koji generated repositories and external repositories are present is an EBS volume mounted as /mnt/koji. Note this was created as ext4 which can sometimes lead to fsck, perhaps xfs would be better fit for our use case.

Services required for koji (postgresql, httpd, kojid, kojira, rsyncd) are only started if required volumes are mounted.

### Ports and Security Group

The instance must be running in a security group with ports:

 * 22
 * 80
 * 443
 * 873 (rsyncd)
 * 44323 (read only monitoring microsite) allowed (all IPv4 TCP).


### Cache and logs

Demanding directories from root volume which is small to /mnt/tmp scratch disk and created symlinks for those:

* /var/cache/mrepo -> /mnt/tmp/cache/mrepo
* /var/log/httpd -> /mnt/tmp/log/httpd

### Hostname

The instance has a floating IP, in /etc/hosts we have an entry for that:

34.224.159.44 koji.katello.org kojihub.katello.org koji kojihub

When the IP changes, make sure this does change as well.

When new instance is booted via AWS, it will have a random hostname assigned. In the rc.local we set the hostname to koji.katello.org on every boot.

### SELinux

SELinux was placed, and remains in, permissive mode since the last Koji rebuild. This should be updated back to enforcing.

### Backups

There is a cron job (/etc/cron.weekly/koji-backup) that performs two actions every week:

Full PostgreSQL database dump into /mnt/koji/backups/postgres.

File system backup of /mnt/tmp (ephemeral storage) into /mnt/koji/backups/ephemeral. This backup skips all files named RPM (these are not needed), duplicity tool is used, no encryption is done. The main purpose of this backup is to store required filesystem structure so koji can be quickly brought up after crash. Since the backup mostly contains directories and build logs, it is not big. To restore that, use:

duplicity restore file:///mnt/koji/backups/ephemeral /mnt/tmp --force --no-encryption

Both backups does not have any rotation and need to be deleted every year. The full backup script looks like:

```bash
#!/bin/bash
/usr/bin/duplicity --full-if-older-than 1M --no-encryption -vWARNING --exclude '/mnt/tmp/**/*rpm' /mnt/tmp file:///mnt/koji/backups/ephemeral
date=`date +"%Y%m%d"`
filename="/mnt/koji/backups/postgres/koji_${date}.dump"
pg_dump -Fc -f "$filename" -U koji koji
```

### Upgrades

We are running CentOS 7 with Koji (1.20) installed from EPEL7 and mrepo installed as an unmanaged standalone file.

To upgrade Koji, see [Koji Upgrade Runbook](https://github.com/theforeman/foreman-infra/blob/master/runbooks/koji/upgrade.md).

### Monitoring

Root email is redirected via /etc/aliases to lzap. Logwatch is configured to send emails daily coming to emails specified in /etc/logwatch/conf/logwatch.conf to the same e-mail. One additional extra free space check is installed in /etc/cron.daily/check-disk-space to send extra email via cron when any of volumes is consuming more than 90% space.

There is a PCP daemon (pmcd) running on the instance and pmlogger active creating archives of performance data in /var/log/pcp/pmlogger (30 days rotation). It is possible to connect and see live data at http://koji.katello.org:44323/grafana/ or http://koji.katello.org:44323/graphite/ (both are JS only applications with read-only API into PCP archives). PCP data can be exported into external Graphite, InfluxDB or Zabbix applications, but none of that has been configured.

Local postfix instance is not configured for relaying so it delivers directly, which can be problem for some freemails/gmail. But it works just fine with redhat.com SMTP server, check delivery first with sendmail if configuring new email.

### Adding external repository

Edit /etc/mrepo.conf and add required entry. Warning: If you delete any repository from here, mrepo will delete all packages from disk and resyncing can take a while. Do not run mrepo with dry-run option as it does perform the changes.

Then run this script in a screen session (takes several hours depending on content) which will resync ALL external repositories. Inform packagers about fresh content which may break future builds as we do not run sync regularly.

```console
mrepo -ug -f -v <repo_label_from_mrepo_config>
```

Verify that repodata was regenerated for external repos:

```console
find /mnt/koji/external-repos/ -name repomd.xml
```

Finally, add external repositories to koji database.

For repos to be used with the main koji builder:

```console
koji add-external-repo fedora-27 file:///mnt/koji/external-repos/www/fedora27-\$arch/RPMS.os/
Created external repo 58
koji add-external-repo fedora-27-updates file:///mnt/koji/external-repos/www/fedora27-\$arch/RPMS.updates/
Created external repo 59
```

For repos to be used with the fedora 28+ koji builder:

```console
koji add-external-repo fedora-28 http://koji.katello.org/kojifiles/external-repos/www/fedora28-\$arch/RPMS.os/
Created external repo 68
koji add-external-repo fedora-28-updates  http://koji.katello.org/kojifiles/external-repos/www/fedora28-\$arch/RPMS.updates/
Created external repo 69
```


## Using Koji as a user

If you want to build in this Koji. You must send a request to the [Infra SIG](https://community.theforeman.org/c/development/infra/24) topic and you'll be sent back a certificate - store it in ~/.katello.cert. Make sure you have ```authtype = ssl``` in /etc/koji.conf.

### Create ~/.koji/foreman-config

```ini
[kkoji]

;configuration for koji cli tool

;url of XMLRPC server
server = http://koji.katello.org/kojihub

;url of web interface
weburl = http://koji.katello.org/koji

;url of package download site
topurl = http://koji.katello.org/

;path to the koji top directory
;topdir = /mnt/koji

;client certificate
cert = ~/.katello.cert

;certificate of the CA that issued the client certificate
ca = ~/.katello-ca.cert

;certificate of the CA that issued the HTTP server certificate
serverca = ~/.katello-ca.cert

;use SSL instead of Kerberos default
authtype = ssl
```

### Create ~/.katello-ca.cert

```
-----BEGIN CERTIFICATE-----
MIIEDzCCAvegAwIBAgIJAJ/i4oLhK2xQMA0GCSqGSIb3DQEBBQUAMGIxCzAJBgNV
BAYTAlVTMQswCQYDVQQIEwJOQzEQMA4GA1UEBxMHUmFsZWlnaDEVMBMGA1UEChMM
S2F0ZWxsbyBLb2ppMQswCQYDVQQLEwJDQTEQMA4GA1UEAxMHa29qaSBDQTAeFw0x
NDA3MDgwOTM0MzBaFw0yNDA3MDUwOTM0MzBaMGIxCzAJBgNVBAYTAlVTMQswCQYD
VQQIEwJOQzEQMA4GA1UEBxMHUmFsZWlnaDEVMBMGA1UEChMMS2F0ZWxsbyBLb2pp
MQswCQYDVQQLEwJDQTEQMA4GA1UEAxMHa29qaSBDQTCCASIwDQYJKoZIhvcNAQEB
BQADggEPADCCAQoCggEBAMvihJFUzcwvIjip+ACWYoVvOlAecSZnox1FSezBPiWm
280FrYf2wN+2s/FWvlDqUheAX03/DcZBPjHiB43v8AJwF3VNCGFu3CaqkQsg1T5s
vw6pvmL0D5gj/wy25OnSOQIGN1EPnb+paCSCN7BRN5DJTk/jDX4ebIbhKFWgC6IH
Jg3jmWvf3ROHXkSumMNMvLtCC91/Y6a28zBu91tL6uCTYBp7G/rVq0hG0doCMrrb
gShVuNq2uoPvQXasjE54Nsd4PnkFbcX+pQcDnhlORBHTVk/m98t+ArOnWBKKQlQh
88jPpVso/jKy6h8R3YHUZY3QY4G3lB7qPJRCI4SaRf8CAwEAAaOBxzCBxDAdBgNV
HQ4EFgQUWaJRvcA/+GaPABgzU0wydC1WDlgwgZQGA1UdIwSBjDCBiYAUWaJRvcA/
+GaPABgzU0wydC1WDlihZqRkMGIxCzAJBgNVBAYTAlVTMQswCQYDVQQIEwJOQzEQ
MA4GA1UEBxMHUmFsZWlnaDEVMBMGA1UEChMMS2F0ZWxsbyBLb2ppMQswCQYDVQQL
EwJDQTEQMA4GA1UEAxMHa29qaSBDQYIJAJ/i4oLhK2xQMAwGA1UdEwQFMAMBAf8w
DQYJKoZIhvcNAQEFBQADggEBAItZgucwDLFJI5U9ejzJXx6yw61/qlkqwNpN5608
PCuz4zdiIH6Ju8dCaOdnWF19aQdASUxc2xjyRs2X6qqZvaX9j4lZXUHxXrGpXTiu
BUJ4OsM3oDbyOvwj3EhK7+rSzjI3Cwx0V2n4xpnCLmfExlMt3Z/LreNUY4bKws0u
nRImQExCmyy+ubY5kGUPEOp8fLhoXVpNyWUX0eTjbiWeqwiFIBgpZrLYFnq0SVCF
lriG9rF2DdvfJFAxZOvbed3EFV/9FrEHhUD8cRdZZMteUh/LzNJZ7JVXTi5lC0Bz
fMKMQGtd6DocgHLpv+5uJg8rAz8bAA3TmnHHk0SCu0iI+tw=
-----END CERTIFICATE-----
```

### Set up a kkoji alias

Using the "kkoji" section created above in the koji config file, aliasing "kkoji" to the koji binary will cause it to use this section.

```bash
mkdir ~/bin
ln -s /usr/bin/koji ~/bin/kkoji
```

If you have an old version of the koji client, you may need to use a bash alias instead.  (Symlink approach is preferable as it works with xargs.)

### Login to Koji WebUI

You do not need to be logged to WebUI. But it is useful if you want to cancel or resubmit task. Or set up notifications. Run:

```bash
openssl pkcs12 -export -inkey ~/.katello.cert -in ~/.katello.cert -CAfile ~/.katello-ca.cert -out katello_browser_cert.p12
```

When prompted for a password, either leave it blank or specify one which is used to secure the output file - you then need to supply it again on import.

And in Firefox do: {{{ Edit -> Preferences -> Advanced -> Encryption -> View Certificates -> Your Certificates -> Import... }}}

### Repos

Repositories are generated automatically using a mash script. Final repositories are stored on the Koji server and hosted at http://koji.katello.org/releases/.

## Adding new builder to our koji

Create new AMI from snapshot. It's running CentOS 7.7. Make
sure security groups is "launch-wizard-1". Make sure it has at least
one local storage and zone is us-east-1d (second can be swap). Note it takes some time (10 minutes or more) for
the initial boot (snapshot was not clean, fsck). Had to set AKI to
aki-1eceaf77 but this should be optional I think.

Edit /etc/hosts and edit entry for koji.katello.org - it must resolve to the internal IP address of the master instance.

Then stop kojid service, mkfs.ext4 on the local disk 1 and mount it:

    /dev/xvdf1 on /mnt/tmp type ext4

Additionally enable swap on local disk 2 (preferred) and enable.

Create some directory structure on /mnt/tmp and symlinks

```bash
mkdir -p /mnt/tmp/var/{lib,tmp,cache} /mnt/tmp/var/lib/mock
chmod 777 /mnt/tmp/var/{lib,tmp,cache} /mnt/tmp/var/lib/mock
mkdir -p /mnt/tmp/external-repos
chmod g+ws /mnt/tmp/var/lib/mock
ln -s /mnt/tmp/var/tmp /var/tmp
ln -s /mnt/tmp/var/lib/mock /var/lib/mock
ln -sf /mnt/tmp/var/cache/yum /var/cache/yum
```

Make sure it has correct permissions.

Add the new builder via koji-admin tool and set's the capacity (4.00 for
m1.large).

Delete the RHUI stuff from /etc/yum.repos.d and
subscribe to updates via RHN CDN. Apply all security updates and reboot.
Take care - EPEL contains newer koji packages, DO NOT update koji from EPEL
(rather disable it).

Now you should be ready to start kojid, before that make sure that NFS
volumes are all mounted up (you will need to create the mountpoints):

```
koji.katello.org:/koji on /mnt/koji type nfs
koji.katello.org:/exports/koji/packages on /mnt/koji/packages type nfs
koji.katello.org:/repos on /mnt/koji/repos type nfs
koji.katello.org:/external-repos on /mnt/tmp/external-repos type nfs
```

Start kojid and watch /var/log/kojid.log.

TODO: Use FS-Cache/NFS cache to speed up NFS access: https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/6/html/Storage_Administration_Guide/fscachenfs.html

## Troubleshooting

### Tasks are note being picked up

Koji builder (kojid) monitors system load and if it exceeds capacity set on koji master (you set it in postgres, defaults to 4) it does not start any tasks. The trick is to set capacity to high nubmer (e.g. 999) and set maxjobs in kojid.conf to amount of CPU cores + 1. Restart kojid and it will start picking things up.

### Tasks are stuck in queue

We use NFS for several directories and NFS can easily get stuck when set to "hard" mode effectively blocking processes forever. Check NFS.

