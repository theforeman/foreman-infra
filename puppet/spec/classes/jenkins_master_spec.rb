require 'spec_helper'

describe 'jenkins_master' do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }

      it { is_expected.to compile.with_all_deps }
      it { is_expected.to contain_package('java-1.8.0-openjdk').with_ensure('absent').that_requires('Package[java-11-openjdk-headless]') }
    end
  end
end
