# This class takes an array of names of secure ssh keys to
# create on a host which will be uploading to hosts configured
# using the receiver class
#
# @param keys Hash of names to user/dir pairs for ssh keys to create
class secure_ssh::rsync::uploader (
  Hash[String[1], Hash[String[1], Any]] $keys = {},
) {
  create_resources('secure_ssh::rsync::uploader_key', $keys)
}
