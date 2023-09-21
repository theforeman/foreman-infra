require 'spec_helper'

describe 'profiles::discourse' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:pre_condition) do
        <<~PUPPET
        class { 'restic':
          password => 'SuperSecret',
        }
        class { 'discourse':
          developer_emails => 'admin@example.com',
          api_key => '1234567890abcdef',
          le_account_email => 'infra@example.com',
          smtp_address => 'mail.example.com',
          smtp_user_name => 'discourse',
          smtp_password => 'changeme',
        }
        PUPPET
      end

      it { is_expected.to compile.with_all_deps }
      it do
        is_expected.to contain_class('restic')
          .with_backup_timer('daily')
          .with_type('sftp')
          .with_host('backups.theforeman.org')
          .with_id("backup-#{facts[:networking]['hostname']}")
      end

      it do
        is_expected.to contain_file('/var/lib/restic/.ssh')
          .with_ensure('directory')
          .with_owner('restic')
          .with_group('restic')
          .with_mode('0700')
      end

      it do
        is_expected.to contain_file('/var/lib/restic/.ssh/id_rsa')
          .with_ensure('file')
          .with_owner('restic')
          .with_group('restic')
          .with_mode('0600')
          .with_content(%r{.+})
      end

      it do
        is_expected.to contain_sshkey('backups.theforeman.org')
          .with_ensure('present')
          .with_type('ecdsa-sha2-nistp256')
          .with_key(%r{^AAAA.+$})
      end
    end
  end
end
