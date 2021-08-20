# GPG Keys

## Summary

After our security incident in July 2014, we planned to try and contain the scope of our GPG keys to avoid resigning lots of content if (or rather, when) a key is compromised or has to be revoked.

* Time based keys: for use with Debian archives. Cycled every two years.
* Release based keys: for use with tarballs, RPMs. Expiry of one year.

## Generating a new key

`generate_gpg` from [theforeman-rel-eng](https://github.com/theforeman/theforeman-rel-eng/) can be used to generate new keys.

See [Generating a new GPG Key for a X.Y release](https://github.com/theforeman/theforeman-rel-eng/#generating-a-new-gpg-key-for-a-xy-release) and [Generating a new GPG Key for signing the Debian repository](https://github.com/theforeman/theforeman-rel-eng/#generating-a-new-gpg-key-for-signing-the-debian-repository) for documentation how to do so.

## Extending the expiration of a key

Sometimes it is required to extend the expiration of a (time based) key.

```
[freight@web01 ~]$ gpg --edit-key <KEYID>
gpg> expire
Changing expiration time for the primary key.
Please specify how long the key should be valid.
         0 = key does not expire
      <n>  = key expires in n days
      <n>w = key expires in n weeks
      <n>m = key expires in n months
      <n>y = key expires in n years
Key is valid for? (0) 2y
Key expires at Sun 20 Aug 2023 06:13:21 AM UTC
Is this correct? (y/N) y
gpg> save
gpg> quit
```

You need to repeat that for every `freight` account (`freight{,stage,archive}@web01`).

## Distributing keys

### Release based keys

RPM users are told in install & upgrade documentation to install foreman-release from the new release, which can contain the keys for that release, making distribution easy.

### Time based keys

Debian archives can be signed with multiple keys (by setting those in `freight.conf`), but key distribution to users is manual right now.

To make our infrastructure aware of the new keys:

* Export private key to `freight{,stage,archive}@web01`:
  * Remove the passphrase: `gpg --homedir "releases/foreman-debian/2021/gnupg/" --edit-key KEY_ID` - enter `passwd`, this will prompt for the current passphrase, enter it, then, when asked for a new one, enter nothing.
  * Export the secret key: `gpg --homedir "releases/foreman-debian/2021/gnupg/" --export-secret-keys --armor > /tmp/debian-new.key`
  * Copy `/tmp/debian-new.key` to `web01`
  * Import the secret key with `gpg --import /tmp/debian-new.key` for each of the freight users: `freight`, `freightarchive`, `freightstage`
* Configure it in `puppet/modules/freight/templates/freight.conf.erb`, examples:
  * [7680053](https://github.com/theforeman/foreman-infra/commit/7680053) - Add 2016 archive key, thus using two keys for a period of time
  * [9f50f62](https://github.com/theforeman/foreman-infra/commit/9f50f62) - Remove 2014 archive signing GPG key
* Configure it in `puppet/modules/slave/templates/pbuilder_f70.erb`, example:
  * [596ece6](https://github.com/theforeman/foreman-infra/commit/596ece6) - add new (2021) key to pbuilder

To make our users aware of the new keys:

* Freight exports the keyring to https://deb.theforeman.org/foreman.asc, so everyone who is regularly syncing that file, is automatically OK.
* Announce new key on discourse, so that people who don't fetch the key regularly, know.
