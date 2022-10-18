# This class takes a hash of names of secure ssh keys to
# permit upload from, the IPs to allow upload from, and
# the script to run when accepting an upload
#
# @param keys  Hash of names of keys to permit access from
class secure_ssh::receiver (
  Hash[String[1], Hash[String[1], Any]] $keys = {},
) {
  create_resources('secure_ssh::receiver_setup', $keys)
}
