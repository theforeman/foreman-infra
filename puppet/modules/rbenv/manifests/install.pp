# @api private
class rbenv::install (
  Array[String[1]] $packages,
) {
  package { $packages:
    ensure => installed,
  }
}
