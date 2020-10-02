# CDN infrastructure

## Overview

We use [Fastly](https://www.fastly.com) as a CDN provider for our web content.

## Who has access?

* Greg
* Ewoud
* Evgeni

## Which vhosts are served via CDN?

* downloads.theforeman.org
* stagingdeb.theforeman.org

## Setup

### Varnish

#### theforeman.org

* Service: `theforeman.org`
* Domains: `theforeman.org` and `www.theforeman.org`
* Backend: `web02.theforeman.org`, with TLS enabled and a health check for `HEAD /introduction.html`
* this service currently gets no traffic as it is not configured in DNS

#### downloads.theforeman.org

* Service: `downloads.theforeman.org`
* Domains: `downloads.theforeman.org`
* Backend: `web02.theforeman.org`, with TLS enabled and a health check for `HEAD /HEADER.html`

#### stagingdeb.theforeman.org

* Service: `stagingdeb.theforeman.org`
* Domains: `stagingdeb.theforeman.org`
* Backend: `web02.theforeman.org`, with TLS enabled and a health check for `HEAD /HEADER.html`

### TLS

Fastly provides a shared certificate which has `theforeman.org` and `*.theforeman.org` added. (There is a `_globalsign-domain-verification` `TXT` record in the theforeman.org DNS zone for that.)

### DNS

Each vhost needs a CNAME pointing at `p2.shared.global.fastly.net` or `dualstack.p2.shared.global.fastly.net` for a DualStack setup.

## TODO

* Investigate logging posibilities
* Move more vhosts as soon as the current ones are deemed stable
