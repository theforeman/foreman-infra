require 'spec_helper'

describe 'jenkins_node' do
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
        it { is_expected.to contain_users__account('jenkins').with_sudo(false) }
        if facts[:osfamily] == 'Debian'
          it { is_expected.to contain_class('sudo') }
          it { is_expected.to contain_sudo__conf('sudo-puppet-jenkins').with_content('jenkins ALL=NOPASSWD: ALL') }
        else
          it { is_expected.not_to contain_class('sudo') }
        end

        if facts[:osfamily] == 'Debian'
          it { is_expected.to contain_file('/etc/pbuilder/bullseye64/hooks/A10nozstd').with_ensure('absent') }
          it { is_expected.to contain_file('/etc/pbuilder/jammy64/hooks/A10nozstd').with_ensure('present') }
          it { is_expected.to contain_file('/etc/pbuilder/bullseye64/hooks/C10foremanlog').with_ensure('present') }
          it { is_expected.to contain_file('/etc/pbuilder/bullseye64/hooks/D80no-man-db-rebuild').with_ensure('present') }
          it { is_expected.to contain_file('/etc/pbuilder/bullseye64/hooks/F60addforemanrepo').with_ensure('present') }
          it { is_expected.to contain_file('/etc/pbuilder/bullseye64/hooks/F65-add-backport-repos').with_ensure('absent') }
          it { is_expected.to contain_file('/etc/pbuilder/bullseye64/hooks/F66-add-nodesource-repos').with_ensure('present') }
          it { is_expected.to contain_file('/etc/pbuilder/bullseye64/hooks/F66-add-nodesource-nodistro-repos').with_ensure('absent') }
          it { is_expected.to contain_file('/etc/pbuilder/jammy64/hooks/F66-add-nodesource-repos').with_ensure('absent') }
          it { is_expected.to contain_file('/etc/pbuilder/jammy64/hooks/F66-add-nodesource-nodistro-repos').with_ensure('present') }
          it { is_expected.to contain_file('/etc/pbuilder/bookworm64/hooks/F66-add-nodesource-repos').with_ensure('absent') }
          it { is_expected.to contain_file('/etc/pbuilder/bookworm64/hooks/F66-add-nodesource-nodistro-repos').with_ensure('absent') }
          it { is_expected.to contain_file('/etc/pbuilder/bullseye64/hooks/F67-add-puppet-repos').with_ensure('present') }
          it { is_expected.to contain_file('/etc/pbuilder/bullseye64/hooks/F70aptupdate').with_ensure('present') }
          it { is_expected.to contain_file('/etc/pbuilder/bullseye64/hooks/F99printrepos').with_ensure('present') }
        end
      end

      context "packaging only node" do
        let(:params) do
          {uploader: false, packaging: true, unittests: false}
        end
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('jenkins_node::packaging') }
        it { is_expected.not_to contain_class('jenkins_node::rvm') }
        it { is_expected.to contain_package('jq') }
      end

      if facts[:osfamily] == 'RedHat'
        context "unittest only node" do
          let(:params) do
            {uploader: false, packaging: false, unittests: true}
          end

          it { is_expected.to compile.with_all_deps }
          it { is_expected.not_to contain_class('jenkins_node::packaging') }
          it { is_expected.to contain_class('jenkins_node::postgresql') }

          if ['9', '8'].include?(facts[:operatingsystemrelease])
            it { is_expected.to contain_class('jenkins_node::rbenv') }
          end

          if ['8', '7'].include?(facts[:operatingsystemrelease])
            it { is_expected.to contain_class('jenkins_node::rvm') }
          end
        end
      end
    end
  end
end
