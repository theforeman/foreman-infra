class deploy::slave {
  secure_ssh::uploader_key { 'deploy':
    user => 'jenkins',
    dir  => '/var/lib/workspace/workspace/deploy_key',
  }
}
