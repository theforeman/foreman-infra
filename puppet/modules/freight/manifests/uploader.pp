# Cheap class to deploy an SSH private key for use in contacting the
# freight server to upload deb packages for signing
#
class freight::uploader {

  secure_ssh::rsync::uploader_key { 'freight':
    user       => 'jenkins',
    dir        => '/var/lib/workspace/workspace/deb_key',
    manage_dir => true,
  }

  secure_ssh::rsync::uploader_key { 'freightstage':
    user       => 'jenkins',
    dir        => '/var/lib/workspace/workspace/staging_key',
    manage_dir => true,
  }

  secure_ssh::uploader_key { 'deploy_debs':
    user => 'jenkins',
    dir  => '/var/lib/workspace/workspace/deploy_debs_key',
  }
}
