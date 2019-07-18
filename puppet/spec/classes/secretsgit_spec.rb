require 'spec_helper'

describe 'secretsgit' do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let :facts do
        facts
      end

      context 'default' do
        it { is_expected.to contain_group 'secretsgit' }
        it do is_expected.to contain_file('/srv/secretsgit').with(
              ensure: 'directory',
              owner: 'root',
              group: 'secretsgit',
              mode: '2770'
            )
        end
      end

      context "with userlistt" do
          let(:params) do
            {
              users: ['user1', 'user2'],
            }
          end
          let(:pre_condition) { 'user{["user1", "user2"]: ensure => present}' }
          it { is_expected.to contain_user('user1').with_groups(['secretsgit']) }
          it { is_expected.to contain_user('user2').with_groups(['secretsgit']) }
      end
    end

  end
end
