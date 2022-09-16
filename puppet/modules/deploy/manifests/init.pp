# @summary Set up a deployment of Puppet environments
#
# @param user
#   The username for the user
class deploy (
  String[1] $user = 'deploypuppet',
) {
  # TODO: install g10k in $PATH

  secure_ssh::receiver_setup { 'deploy':
    user           => $user,
    foreman_search => 'host ~ node*.jenkins.osuosl.theforeman.org and (name = external_ip4 or name = external_ip6)',
    script_content => file('deploy/script.sh'),
  }
}
