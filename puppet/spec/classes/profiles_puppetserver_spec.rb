require 'spec_helper'

describe 'profiles::puppetserver' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:pre_condition) do
        <<~PUPPET
        class { 'puppet':
          server_environments_owner => 'deploypuppet',
        }
        PUPPET
      end

      it { is_expected.to compile.with_all_deps }
    end
  end
end
