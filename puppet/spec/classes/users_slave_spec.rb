require 'spec_helper'

describe 'users::slave' do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      it { is_expected.to compile.with_all_deps }
      if facts[:osfamily] == 'Debian'
        it { is_expected.to contain_users__account('jenkins').with_sudo('ALL=NOPASSWD: ALL') }
      else
        it { is_expected.to contain_users__account('jenkins').with_sudo('') }
      end
    end
  end
end
