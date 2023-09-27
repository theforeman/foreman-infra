# Infrastructure - Discourse

## Host - community.theforeman.org

Discourse runs in a VM on our Conova hypvervisor, and is linked to our Puppet infra so the usual people have SSH key access.
Backups of the DB dumps and attachments are done to our normal backup infrastructure daily.

## What's running?

Discourse runs in Docker, so very little is running at the main host level. There are 2 containers running:

1. The main Discourse app, containing Rails, Redis, Sidekiq, and PostgreSQL. Listens on 80 and 443 and provides it's own Let's Encrypt setup
2. A Postfix container listening on 25 which handles incoming mail and then passes it to Discourse for turning into posts

## Locations

All the work is done in `/var/discourse`. In that directory you'll find:

* `containers` directory which contains YAML files specifying the `app` and `mail-receiver` definitions (managed by the `discourse` Puppet module)
* `shared` directory containing the permanent volumes mounted into Docker (backups are in here)
* `launcher` bash script for interacting with the containers

## Useful commands

### Mail-receiver

There's really only one useful command here - `./launcher logs` will get you the recent logs from the container. Combined with grep, you can check to see if a specific mail arrived, eg:

```console
$ ./launcher logs mail-receiver | egrep "from=|receive-mail"
<22>Dec 26 06:19:44 postfix/qmgr[80]: 54787280723: from=<email-redacted>, size=10324, nrcpt=1 (queue active)
<23>Dec 26 06:19:44 receive-mail[17867]: Recipient: reply+<token-redacted>`community.theforeman.org
```

### Discourse

If for some reason you need access to the Rails instance itself, you can enter the container with `./launcher enter app`. That will put you at the root of the rails app, so you can immediately do things like `bundle exec rake -T`

For basic app control, `start`, `stop`, and `restart` are available, of course.

#### restarting

```console
$ cd /var/discourse ; sudo ./launcher restart app
```

If for some reason the Discourse WebUI upgrade process fails, it will direct you to do a CLI upgrade, which is usually `./launcher rebuild app` but on-screen notes are usually provided.

## Backup and Restore

### Backup

Discourse itself performs a backup daily (see Admin > Backups).
These backups are then transferred to our normal backup infrastructure.
They contain all the content for Discourse itself (database, files).

### Restore

Backups can be restored by setting up a new Discourse instance, copying the tarball to the backups folder, and then restoring from within the UI or console.
Note you have to enable Restore from the Settings UI or console.

#### Restore via console

1. Create a fresh machine with the `discourse` Puppet module applied to it.
   Make sure `community.theforeman.org` already points to that system or override `$hostname` in Puppet to make Let's Encrypt and friends work correctly.
2. Let Discourse rebuild the main app and start it: `./launcher rebuild app`.
   When this is done, you will have an empty, fresh Discourse installation.
3. Obtain a backup tarball and place it into `/var/discourse/shared/standalone/backups/default`.
4. Enter the `app` container: `./launcher enter app`.
5. Enable restores: `discourse enable_restore`
6. Restore the backup: `discourse restore sitename-2019-02-03-042252-v20190130013015.tar.gz`
7. Leave the `app` container: `exit`
8. Rebuild the `app` to migrate the DB etc: `./launcher rebuild app`
9. Rebuild the `mail-receiver` container: `./launcher rebuild mail-receiver`
