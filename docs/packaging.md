# Packaging

Foreman builds RPM and DEB packages for its users.
This page summarizes how the and where the packages are built.

## DEB

### Building

The packages are built by [Jenkins](jenkins.md) on a Jenkins node configured using the [`jenkins_node::packaging::debian`](https://github.com/theforeman/foreman-infra/blob/master/puppet/modules/jenkins_node/manifests/packaging/debian.pp) Puppet class.

Jenkins prepares a Debian source tree and then executes `pbuilder` to build the package for each supported Debian/Ubuntu release.

### Publishing

Once built the packages are published to `deb.theforeman.org` or `stagingdeb.theforeman.org` on the [DEB repository server](repo-deb.md).

Packages from the `plugins` directory land directly in the respective repository on `deb.theforeman.org`, while those from `foreman` and `dependencies` land on `stagingdeb.theforeman.org` to be tested by [`foreman-deb.groovy`](https://github.com/theforeman/jenkins-jobs/blob/master/theforeman.org/pipelines/release/pipelines/foreman-deb.groovy) and pushed to `deb.theforeman.org` afterwards.

### Pull Requests

Pull Requests are built using the same stack and published to `stagingdeb.theforeman.org` with the PR author's name as the repository name.

## RPM

### Building

The packages are built by [Jenkins](jenkins.md) on a Jenkins node configured using the [`jenkins_node::packaging::rpm`](https://github.com/theforeman/foreman-infra/blob/master/puppet/modules/jenkins_node/manifests/packaging/rpm.pp) Puppet class.

Jenkins prepares an SRPM and submits the build to [COPR](https://copr.fedorainfracloud.org/), which performs the actual build.

COPR requires a token for the [`theforeman-bot`](https://accounts.fedoraproject.org/user/theforeman-bot/) user to work.
The tokens have a validity of 6 months and need rotation once expired.
Jenkins stores the COPR configuration, which includes the token, in the `theforeman-bot-copr` credential.

### Publishing

COPR publishes the built packages in own repositories, but doesn't support neither filtering nor gating of the built packages.
Instead we use a process where a staging repository is built based on the COPR content, published to `stagingyum.theforeman.org`, tests are executed and once the tests pass the repository is published to `yum.theforeman.org`.

For nightly, the process can be seen in [`foreman-rpm.groovy`](https://github.com/theforeman/jenkins-jobs/blob/master/theforeman.org/pipelines/release/pipelines/foreman-rpm.groovy).
For releases, the process is described in the [release procedure](https://github.com/theforeman/theforeman-rel-eng/blob/master/procedures/foreman/release.md.erb).

All user-facing repositories are hosted on the [RPM repository server](repo-rpm.md).

### Pull Requests against the packaging repository

Pull Requests against `foreman-packaging` are built by Jenkins in special, temporary COPR projects.

### Pull Requests against the source repositories

Several repositories utilize [Packit](https://packit.dev) to build RPM packages when a Pull Request is opened.
Packit uses the RPM spec from `foreman-packaging` and builds the packages on COPR.
More information on our Packit setup can be found in:
- [Packit for Foreman - get production RPMs from PRs](https://community.theforeman.org/t/packit-for-foreman-get-production-rpms-from-prs/32412)
- [Packit-based nightlies or how to properly test plugins in production](https://theforeman.org/2025/11/packit-based-nightlies-or-how-to-properly-test-plugins-in-production.html)
