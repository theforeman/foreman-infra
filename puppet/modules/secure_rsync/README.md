# Puppet module for managing secure ways to SSH or copy files using easily revokable ssh keys

This module uses Puppet to set up ssh and optionally rsync in such a way that:

* The key is revokable from the puppetmaster
* The uploader cannot use the key for anything other than running a single script, or
  optionally rsyncing files
* The uploader cannot upload to anywhere other than the intended location
* The receiver can run an arbitrary script upon receiving the files to sanitize
  and distribute them to the correct place

As an example, this module is used in the TheForeman infratructure to

* Build the `theforeman.org` website on a jenkins slave
* Rsync the compiled static site to `theforeman.org:~website/rsync_cache/`
* The webserver then chmod's all the files correctly and copies them to the vhost,
  thus allowing SELinux to prevent direct scp to the vhost.

## Requirements

Depends upon https://github.com/GregSutcliffe/puppet-ssh_statickeys

## Example config

There are two ways to use this module

### Adding resources to your manifests

If you wish to simply add extra resources to your manifests, the defines in
this module can be called directly. For example, if you have a website and a
slave which pushes content to the site, you might already have a "website"
class and a "slave" class. In which case you might add the following:

```
class slave {
  secure_rsync::uploader_key { 'website':
    user       => 'jenkins',
    dir        => '/home/jenkins',
    manage_dir => true,
  }
  # rest of your slave class here...
}

class website {
  secure_rsync::receiver_setup { 'website':
    user        => 'website',
    allowed_ips => [ '1.2.3.4' ],
  }
  # rest of your website class here ...
}

### Specifying all config from the ENC

Alternatively, if you wish to define all the appropriate config from your ENC,
there is a set of wrapper classes you can use to do this:

On the uploader, apply a hash of private & public keys to create:

```
$keys = {
  "test" => {
    "user"       => "jenkins",
    "dir"        => "/home/jenkins",
    "manage_dir" => "true",
  }
}
class { 'secure_rsync::uploader': keys => $keys }
```

On the receiver, apply a hash containing the key names and actions to take:

```
$conf = {
  "test" => {
    "user" => "website",
    "allowed_ips" => ['1.2.3.4','5.6.7.8']
  }
}
class { 'secure_rsync::receiver': keys => $conf }
```

