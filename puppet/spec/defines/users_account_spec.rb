require 'spec_helper'

describe 'users::account' do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:title) { 'jenkins' }
      let(:facts) { facts }

      context 'default parameters' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_user('jenkins').with_ensure('present') }
        it { is_expected.to contain_file('/home/jenkins').with_ensure('directory') }
      end

      context 'without sudo' do
        let(:params) do
          {sudo: ''}
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_sudo__conf('sudo-puppet-jenkins').with_ensure('absent') }
      end

      context 'ensure => absent' do
        let(:params) do
          {ensure: 'absent'}
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_user('jenkins').with_ensure('absent') }
        it { is_expected.to contain_sudo__conf('sudo-puppet-jenkins').with_ensure('absent') }
        it { is_expected.not_to contain_file('/home/jenkins') }
      end
    end
  end
end
