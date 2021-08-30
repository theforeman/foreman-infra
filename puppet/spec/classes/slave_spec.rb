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
          it { is_expected.to contain_users__account('jenkins').with_sudo('ALL=NOPASSWD: ALL') }
        else
          it { is_expected.to contain_users__account('jenkins').with_sudo('') }
        end

        if facts[:osfamily] == 'Debian'
          it { is_expected.to contain_file('/etc/pbuilder/buster64/hooks/C10foremanlog').with_ensure('present') }
          it { is_expected.to contain_file('/etc/pbuilder/buster64/hooks/D80no-man-db-rebuild').with_ensure('present') }
          it { is_expected.to contain_file('/etc/pbuilder/buster64/hooks/F60addforemanrepo').with_ensure('present') }
          it { is_expected.to contain_file('/etc/pbuilder/buster64/hooks/F70aptupdate').with_ensure('present') }
          it { is_expected.to contain_file('/etc/pbuilder/buster64/hooks/F99printrepos').with_ensure('present') }
        end
      end
    end
  end
end
