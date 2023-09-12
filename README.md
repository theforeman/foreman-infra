# Foreman Infrastructure

This repo contains puppet modules that are used to manage infrastructure used by the Foreman project. These modules manage many different pieces of software, including Jenkins build slaves, package build machines, the Jenkins frontend, as well as an internal Foreman instance and puppetserver.

View the [documentation](https://theforeman.github.io/foreman-infra).

## Puppet module directories
The `puppet` folder contains the following directories for Puppet modules:

### `external_modules`
Externally maintained modules. Preferably straight from the [Puppet Forge](https://forge.puppet.com) but potentially via git.

### `modules`
Our own custom modules, relevant only in this particular repository for this particular setup.

### `test_modules`
Modules relevant only in the Puppet spec tests, e.g. Puppet's core modules, that are coming bundled with the agent in a real setup.
