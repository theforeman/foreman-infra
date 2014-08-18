# Cheap class to deploy an SSH private key for use in contacting the web server
# to upload the compiled static site
#
class web::uploader {

  secure_rsync::rsync::uploader_key { 'web':
    user       => 'jenkins',
    dir        => '/var/lib/workspace/workspace',
    manage_dir => true,
  }

}
