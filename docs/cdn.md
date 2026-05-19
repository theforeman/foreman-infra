# CDN

[Fastly](https://www.fastly.com) sponsors the CDN for Foreman.

## Configuration

The configuration happens through the `ansible/fastly.yml` Ansible playbook in this repository.

The major points of the configuration are:

* Set the backend to the right webserver (website01, repo-rpm01, repo-deb01)
* Enable shielding: a central system fetches the assets and then distributes them across the CDN instead of each CDN node fetches them itself, this costs more CDN traffic, but is usually faster
* Configure a health-check and serve stale content when it fails

## TLS

Fastly provides a shared certificate which has `theforeman.org` and `*.theforeman.org` as DNSAltName.

This certificate is signed by GlobalSign and we have a `_globalsign-domain-verification` TXT record in the `theforeman.org` DNS zone for verification of ownership.

## DNS

Each vhost has a CNAME pointing at `dualstack.p2.shared.global.fastly.net` which is the Fastly global, dualstack loadbalancer.
