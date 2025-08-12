# Redmine

| | redmine01.conova.theforeman.org |
| - | - |
| type | Libvirt VM |
| OS | CentOS Stream 9 |
| CPUs | 8 |
| RAM | 8GB |
| Storage | /dev/vda (30GB) |
| Managed by | [profiles::redmine](https://github.com/theforeman/foreman-infra/blob/master/puppet/modules/profiles/manifests/redmine.pp) |

## Deployment

Redmine is deployed using Ruby 3.0 and PSQL 13.

A copy of the git repository is stored here: https://github.com/theforeman/redmine/. When upgrading Redmine it is required to rebase our changes onto the new upstream ref, and then push that back to our fork.

The repository is a copy of Redmine's master branch with the following changes:

* e-mail configuration using mailgun.com, under config/configuration.yml
* a few local customisation commits such as images and spider blocks

This should be kept up to date from the Redmine project by merging in upstream/master on a regular basis.

Note there are also some cron jobs (handled in foreman-infra Puppet code), and plugins (some of which are tracked as submodules, but care should be taken).

## Backups

The Redmine database and files are backed up daily to the Puppetserver via restic. Should you need to recover the setup, apply the Puppet manifests from foreman-infra to a new Centos host, and then restore the backup DB to PostgreSQL and the files to `/var/lib/redmine`.
