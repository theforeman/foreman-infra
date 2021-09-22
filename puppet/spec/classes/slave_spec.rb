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
      end

      context "packaging only node" do
        let(:params) do
          {uploader: false, packaging: true, unittests: false}
        end
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('slave::packaging') }
        it { is_expected.not_to contain_class('slave::rvm') }
        it { is_expected.to contain_package('jq') }
      end

      context "unittest only node" do
        let(:params) do
          {uploader: false, packaging: false, unittests: true}
        end
        it { is_expected.to compile.with_all_deps }
        it { is_expected.not_to contain_class('slave::packaging') }
        it { is_expected.to contain_class('slave::rvm') }
        it { is_expected.to contain_class('slave::postgresql') }
      end
    end
  end
end
