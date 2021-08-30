require 'spec_helper'

describe 'slave' do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let :facts do
        facts
      end

      context "without uploader" do
        let(:params) do
          {uploader: false}
        end
        it { is_expected.to compile.with_all_deps }
        if facts[:osfamily] == 'Debian'
          it { is_expected.to contain_users__account('jenkins').with_sudo("ALL=NOPASSWD: ALL\nDefaults:jenkins env_keep += FOREMAN_VERSION") }
        else
          it { is_expected.to contain_users__account('jenkins').with_sudo('') }
        end
      end
    end
  end
end
