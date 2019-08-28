require 'spec_helper'

describe 'slave' do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let :facts do
        facts
      end

      context "with default parameters" do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_package('vagrant').with_ensure('absent') }
        it { is_expected.to contain_file('/home/jenkins/.vagrant.d').with_ensure('absent') }
      end
    end
  end
end
