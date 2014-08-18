# This class takes an array of names of secure ssh keys to
# create on a host which will be uploading to hosts configured
# using the receiver class
#
# === Parameters:
#
# $keys  Hash of names to user/dir pairs for ssh keys to create
#        type:hash
#
class secure_rsync::rsync::uploader (
  $keys = {}
) {

  validate_hash($keys)
  create_resources(secure_rsync::rsync::uploader_key,$keys)

}
