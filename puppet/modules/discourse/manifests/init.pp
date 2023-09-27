class discourse(
  String $developer_emails,
  String $api_key,
  String $le_account_email,
  Stdlib::Host $smtp_address,
  String $smtp_user_name,
  String $smtp_password,
  Stdlib::Port $smtp_port = 587,
  Stdlib::Absolutepath $root = '/var/discourse',
  Stdlib::Host $hostname = 'community.theforeman.org',
) {
  ensure_packages(['git'])

  vcsrepo { $root:
    ensure   => present,
    provider => git,
    source   => 'https://github.com/discourse/discourse_docker.git',
  }

  $containers = "${root}/containers"

  file { $containers:
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0700',
    require => Vcsrepo[$root],
  }

  $app_context = {
    'root'             => $root,
    'hostname'         => $hostname,
    'developer_emails' => $developer_emails,
    'smtp_address'     => $smtp_address,
    'smtp_port'        => $smtp_port,
    'smtp_user_name'   => $smtp_user_name,
    'smtp_password'    => $smtp_password,
    'le_account_email' => $le_account_email,
  }

  file { "${containers}/app.yml":
    owner   => 'root',
    group   => 'root',
    mode    => '0700',
    content => epp('discourse/app.yml.epp', $app_context),
  }

  $mail_context = {
    'root'     => $root,
    'hostname' => $hostname,
    'api_key'  => $api_key,
  }

  file { "${containers}/mail-receiver.yml":
    owner   => 'root',
    group   => 'root',
    mode    => '0700',
    content => epp('discourse/mail-receiver.yml.epp', $mail_context ),
  }
}
