# Infrastructure - Discourse

## Host - community.theforeman.org

Discourse runs on our Scaleway account, and is linked to our Puppet infra so the usual people have SSH key access. Backups to the puppetserver of the DB dumps, attachments, and container definitions are enabled too.

## What's running?

Discourse runs in Docker, so very little is running at the main host level. There are 2 containers running:

1. The main Discourse app, containing Rails, Redis, Sidekiq, and PSQL. Listens on 80 and 443 and provides it's own Let's Encrypt setup
2. A Postfix container listening on 25 which handles incoming mail and then passes it to Discourse for turning into posts

## Locations

All the work is done in `/var/discourse`. In that directory you'll find:

* `containers` directory which contains YAML files specifying the `app` and `mail-receiver` definitions
* `shared` directory containing the permanent volumes mounted into Docker (backups are in here)
* `launcher` bash script for interacting with the containers

## Useful commands

### Mail-receiver

There's really only one useful command here - `./launcher logs` will get you the recent logs from the container. Combined with grep, you can check to see if a specific mail arrived, eg:

```
$ ./launcher logs mail-receiver | egrep "from=|receive-mail"
<22>Dec 26 06:19:44 postfix/qmgr[80]: 54787280723: from=<email-redacted>, size=10324, nrcpt=1 (queue active)
<23>Dec 26 06:19:44 receive-mail[17867]: Recipient: reply+<token-redacted>`community.theforeman.org
```

### Discourse

If for some reason you need access to the Rails instance itself, you can enter the container with `./launcher enter app`. That will put you at the root of the rails app, so you can immediately do things like `bundle exec rake -T`

For basic app control, `start`, `stop`, and `restart` are available, of course.

#### restarting

    cd /var/discourse ; sudo ./launcher restart app


If for some reason the Discourse WebUI upgrade process fails, it will direct you to do a CLI upgrade, which is usually `./launcher rebuild app` but on-screen notes are usually provided.

## Disaster recovery

There are two forms of backup:

### Volume snapshots

Every day [a script](https://github.com/theforeman/foreman-infra/blob/master/puppet/modules/scaleway/files/manage_snapshots.rb) runs on the Discourse VM which talks to the Scaleway Snapshot API, triggers a new snapshot, and then (on success) cleans the older images away. The most recent 3 snapshots are retained.

In the event of the VM completely dying, this is your starting point, as it should be a complete image of the whole system, with all API keys etc.

### Discourse content tarballs

Discourse itself performs a backup daily (see Admin > Backups), which runs ~12 hours after the snapshot above, to provide staggered cover. This contains all the content for Discourse itself, and can be restored by setting up a new Discourse instance, copying the tarball to the backups folder, and then restoring from within the UI. Note you have to enable Restore from the Settings UI.

The backup tarballs, along with the container definitions in `/var/discourse/containers` are backed up nightly to the Puppetmaster, in case of complete failure of the Scaleway system.
