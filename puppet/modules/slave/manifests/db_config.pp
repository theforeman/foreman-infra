# @api private
define slave::db_config (
  Enum['file', 'absent'] $ensure = 'file',
  Stdlib::Absolutepath $jenkins_home = '/home/jenkins',
  String[1] $jenkins_user = 'jenkins',
  String[1] $jenkins_group = 'jenkins',
) {
  if $ensure == 'file' {
    $content = file("${module_name}/db/${title}")
  } else {
    $content = undef
  }

  file { "${jenkins_home}/${title}.db.yaml":
    ensure  => $ensure,
    content => $content,
    owner   => $jenkins_user,
    group   => $jenkins_group,
  }
}
