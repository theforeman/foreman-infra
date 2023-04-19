require 'spec_helper'

describe 'profiles::jenkins::controller' do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      let(:pre_condition) do
        <<~PUPPET
        class { 'restic':
          password => 'SuperSecret',
        }
        PUPPET
      end
      let(:params) do
        {
          jenkins_job_builder_username: 'user',
          jenkins_job_builder_password: 'password',
        }
      end

      it { is_expected.to compile.with_all_deps }
    end
  end
end
