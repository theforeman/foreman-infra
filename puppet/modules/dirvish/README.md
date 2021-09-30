# dirvish

Module for creating and managing a backup solution using Dirvish. The module will
deploy Dirvish to the backup server (the host with `dirvish` applied) and then create
a vault for each entry in $vaults. The module will attempt to initialize the vault,
so it is recommended to deploy the `dirvish::client` classes first.

## Dependencies

* puppetlabs-stdlib
* ssh (no metadata so not listed in metadata.json)

## Parameters

### init.pp
[*backup_location*]
The core path that the backups should live in. Defaults to `/srv/backups`. The
parent of this path should exist, or Puppet will be unable to create the dir.

[*vaults*]
A hash of data describing the backups to be performed.

### client.pp
[*pre_template*]
The location of a template that should be used to populate `/etc/dirvish/pre_client`
on the clients.

[*pre_script*]
A string to be deployed to be deployed to `/etc/dirvish/pre_client`. Overrides
`pre_template` if specified.

If neither of these are specified, the `pre_client` script will simply execute `true`

[*declare_rsync*]
Set this to false if you have rsync declared elsewhere in your manifest.

Examples
--------

    class { dirvish:
      backup_location => '/backups'
    }

This will create a non-functional sample backup configuration in `/backups`. For a
more complete example backing up `/etc` with some sample excludes on `localhost`, try:

    class { 'dirvish::client':
      pre_template => "mystuff/dirvish_pre.erb"
    } ->
    class { 'dirvish':
      vaults => {
                   testbackup => {
                     client   => $::hostname,
                     tree     => '/etc',
                     excludes => [
                       '*hosts*',
                       '/etc/puppet'
                     ]
                   }
                 },
      backup_location => '/backups'
    }

Copyright
---------

Copyright 2013 Greg Sutcliffe

License
-------

GPL3

Contact
-------

Greg Sutcliffe <greg.sutcliffe@gmail.com>

Support
-------

Please log tickets and issues at my [github page](https://github/GregSutcliffe/puppet-dirvish)
