require 'spec_helper'

describe 'discourse' do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      let(:pre_condition) do
        <<~PUPPET
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
    end
  end
end
