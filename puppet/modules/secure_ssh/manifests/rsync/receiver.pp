# This class takes a hash of names of rsync ssh keys to
# permit upload from, the IPs to allow upload from, and
# the script to run when accepting an upload
#
# === Parameters:
#
# $keys  Hash of names of keys to permit access from
#        type:hash
#
class secure_ssh::rsync::receiver (
  $keys = {}
) {

  validate_hash($keys)
  create_resources(secure_ssh::rsync::receiver_setup,$keys)

}
