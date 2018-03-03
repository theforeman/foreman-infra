require 'spec_helper'

describe 'slave' do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let :facts do
        facts
      end

      context "with default parameters" do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.not_to contain_class('slave::vagrant') }
      end

      context "with vagrant" do
        let :params do
          {
            rackspace_username: 'user',
            rackspace_api_key: 'key',
          }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('slave::vagrant') }
      end
    end
  end
end
