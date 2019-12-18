Koji upgrade
==============

Issue
-----
* You want to upgrade [Koji](http://koji.katello.org) to a newer version

Resolution
----------
* Shut down koji services on `koji-fedora28-builder` and `kojibuilder1`.
  * koji-fedora28-builder
    ```sh
    systemctl stop kojid
    ```
  * kojibuilder1
    ```sh
    systemctl stop kojid kojira httpd postgresql
    ```
* Take snapshots in aws.
  * EBS -> Volumes
  * Right click on “koji 4 root volume” -> create snapshot
  * Right click on “koji4 data volume /mnt/koji” -> create snapshot
    * You can still use the host os while snapshot is `pending`,
    it refers to the transfer to amazon s3.

* update vms to latest software.
  * kojibuilder1
    * `# yum update`
    * Remove `/etc/httpd/conf.d/{kojihub,kojiweb,ssl}.conf`
      * We have our configs in `/etc/httpd/conf.modules.d` at the moment
  * koji-fedora28-builder
    ```sh
    systemctl disable kojid  # to keep it from erroring out across reboots

    dnf upgrade --refresh
    
    # if Fedora is out of date, upgrade it    
    dnf install dnf-plugin-system-upgrade
    # for each release, upgrade one at a time
    dnf system-upgrade download --refresh --releasever={current + 1}
    dnf system-upgrade reboot
    ```

* Run koji database migrations
  ```sh
  # for each .y step, run that .y's migration script
  psql koji koji  </usr/share/doc/koji-{version}/docs/schema-upgrade-1.{y-1}-1.{y}.sql
  ```
* Start koji services on koji-fedora28-builder and kojibuilder1.
  * kojibuilder1
     ```sh
    systemctl start postgresql httpd kojira kojid
    ```
  * koji-fedora28-builder
    ```sh
    systemctl enable --now kojid
    ```
* Verify successful scratch build against a tag, then test nightlies



Runs
----

### 2019-12-17

* Run specific info:
  * Database migrations ran:
    * `/usr/share/doc/koji-1.19.1/docs/schema-upgrade-1.15-1.16.sql`
      * Edited line 32, set user value to 2 instead of 1 (we have no user id 1)
    * `/usr/share/doc/koji-1.19.1/docs/schema-upgrade-1.16-1.17.sql`
    * `/usr/share/doc/koji/docs/schema-upgrade-1.17-1.18.sql`
    * `/usr/share/doc/koji/docs/schema-upgrade-1.18-1.19.sql`
  * koji-fedora28-builder
    * Upgraded from 28-31, one number increase at a time


