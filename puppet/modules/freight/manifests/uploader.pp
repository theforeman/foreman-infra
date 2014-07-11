# Cheap class to deploy an SSH private key for use in contacting the
# freight server to upload deb packages for signing
#
class freight::uploader {

  secure_rsync::uploader_key { 'freight':
    user       => 'jenkins',
    dir        => '/var/lib/workspace/workspace',
    manage_dir => true,
  }

  secure_rsync::uploader_key { 'freightstage':
    user       => 'jenkins',
    dir        => '/var/lib/workspace/workspace',
    manage_dir => true,
  }

}
