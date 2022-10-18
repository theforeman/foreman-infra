require 'spec_helper'

describe 'profiles::base::sysadmins' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      context 'without ENC' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_mailalias('sysadmins').with_recipient(['/dev/null']) }
      end

      context 'with ENC' do
        # The ENC parameters aren't really `facts`.
        # In reality they wouldn't appear in the `$facts` hash, but with
        # rspec-puppet `let :facts` is still needed to set them as
        # top-scope variables.
        let(:facts) do
          super().merge(
            foreman_users: {
              my_username: {
                mail: 'user@example.com',
              },
              other: {
                mail: 'other@example.com',
              },
            }
          )
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_mailalias('sysadmins').with_recipient(['user@example.com', 'other@example.com']) }
      end
    end
  end
end
