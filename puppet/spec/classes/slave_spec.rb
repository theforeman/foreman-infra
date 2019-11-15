require 'spec_helper'

describe 'slave' do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let :facts do
        facts
      end

      context "with default parameters" do
        it { is_expected.to compile.with_all_deps }
      end
    end
  end
end
