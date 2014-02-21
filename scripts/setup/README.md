# Provisioning a new host with Ansible

## Local setup
If you haven't already got Ansible installed, then the first step is to get it running on your workstation. It's nicely
packaged for EPEL, Fedora, Debian, and is available in Homebrew so use one those tools to get it installed. The package
name is 'ansible' everywhere.

## Run Ansible on the newly provisioned host
1. Have the password that Rackspace gave you for the instance at the ready.
2. `ansible-playbook -i "<the host's IP>," scripts/setup/setup.yml -k`

## Todo's
* Using Ansible's built-in provisioning to create new machines as part of the setup process
* Consider configuring basic security (i.e. a reason SSH config) before Puppet ever runs
