class deploy::slave {
  secure_ssh::uploader_key { 'deploy':
    user => 'jenkins',
    dir  => '/var/lib/workspace/workspace/deploy_key',
  }

  secure_ssh::uploader_key { 'deploy_katello_repos':
    user => 'jenkins',
    dir  => '/var/lib/workspace/workspace/deploy_katello_repos_key',
  }
}
