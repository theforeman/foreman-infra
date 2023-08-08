# Secret storage

The Foreman project uses [gopass](https://github.com/gopasspw/gopass) to store shared secrets.
This is achieved by storing GPG encrypted files in git repositories.

## Client access

First install gopass. On Fedora:

```sh
dnf install gopass
```

Ensure that `gopass` is initialized after installing the first time (and that your GPG private key is present on the system):

```
gopass init <YOUR-PUB-KEY-HASH>
```

## Stores

### Releases

This store is meant for release engineers and can be cloned:

```
gopass clone secrets.theforeman.org:/srv/secretsgit/theforeman-release.git theforeman/releases
```

### Shared

Contains account access for Infra admins.

```
gopass clone secrets.theforeman.org:/srv/secretsgit/theforeman-passwords.git theforeman/shared
```

## Server setup

This is managed by the Puppet class `secretsgit` and served on the `secrets.theforeman.org` hostname. Technically this is a DNS CNAME to the real server.

### Granting access

* Ensure [SSH access](https://theforeman.github.io/foreman-infra/#access) is available
* Add the user to [`secretsgit::users`](https://foreman.theforeman.org/foreman_puppet/puppetclasses/564-secretsgit/edit)
* Add the user's key as a recipient: `gopass sync && gopass recipients add --store theforeman/releases 1234567890ABCDEF && gopass sync`
