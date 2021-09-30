# Cheap class to deploy an SSH private key for use in contacting the
# freight server to upload deb packages for signing
#
# @param user
#   The username for which to deploy the upload key
# @param workspace
#   The workspace where to deploy the key
class freight::uploader(
  String $user,
  Stdlib::Absolutepath $workspace,
) {
  include rsync

  secure_ssh::rsync::uploader_key { 'freight':
    user       => $user,
    dir        => "${workspace}/deb_key",
    manage_dir => true,
  }

  secure_ssh::rsync::uploader_key { 'freightstage':
    user       => $user,
    dir        => "${workspace}/staging_key",
    manage_dir => true,
  }

}
