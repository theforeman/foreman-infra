# Forked from https://github.com/fup/puppet-ssh @ 59684a8ae174
# Rewritten to the modern Puppet functions API
Puppet::Functions.create_function(:'ssh::keygen') do
  # @param name   (the name of the key - e.g 'my_ssh_key')
  #   Optional parameters:
  # @param type   (the key type - default: 'rsa')
  # @param dir    (the subdir of Puppet's vardir to store the key in - default: 'ssh')
  # @param size   (the key size - default 2048)
  # @param public (if specified, reads the public key instead of the private key)
  dispatch :keygen do
    param 'String[1]', :name
    optional_param 'Boolean', :is_public
    # Taken from man ssh-keygen with openssh-clients-8.8p1-9.fc37.x86_64
    optional_param "Enum['dsa', 'ecdsa', 'ecdsa-sk', 'ed25519', 'ed25519-sk', 'rsa']", :type
    optional_param 'Integer[256]', :size
    optional_param 'String[1]', :dir
    return_type 'String'
  end

  def keygen(name, is_public = false, type = 'rsa', size = 2048, dir = 'ssh')
    require 'fileutils'

    case type
    when 'dsa'
      # Ensure dsa uses keylength 1024
      size = 1024
    when 'ecdsa'
      # ECDSA must be 256, 384 or 521 bits
      # Ensure ecdsa uses keylength 521
      size = 521
    end

    parent_dir = File.join(Puppet[:vardir], dir)
    absolute_path = File.join(parent_dir, name)

    # Make sure to write out a directory to init if necessary
    begin
      FileUtils.mkdir_p(parent_dir)
    rescue => e
      # TODO: other exception?
      raise Puppet::ParseError, "ssh::keygen(): Unable to setup ssh keystore directory (#{e}) #{%x[whoami]}"
    end

    # Do my keys exist? Well, keygen if they don't!
    unless File.exists?(absolute_path) then
      command = ['/usr/bin/ssh-keygen', '-t', type, '-b', size, '-P', '', '-f', absolute_path]
      Puppet::Util::Execution.execute(command, failonfail: true)
    end

    # Return ssh key content based on request
    begin
      if is_public
        request = 'public'
        pub_key = File.read("#{absolute_path}.pub")
        pub_key.scan(/^.* (.*) .*$/)[0][0]
      else
        request = 'private'
        File.read(absolute_path)
      end
    rescue => e
      # TODO: other exception?
      raise Puppet::ParseError, "ssh::keygen(): Unable to read ssh #{request} key (#{e})"
    end
  end
end
