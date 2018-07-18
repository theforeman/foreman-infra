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
        it { is_expected.to contain_package('vagrant').with_ensure('absent') }
        it { is_expected.to contain_file('/home/jenkins/.vagrant.d').with_ensure('absent') }
      end

      context "with vagrant" do
        let :params do
          {
            rackspace_username: 'user',
            rackspace_password: 'pass',
            rackspace_tenant: 'tenant',
          }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('slave::vagrant') }
        it do
          is_expected.to contain_file('/home/jenkins/.vagrant.d/Vagrantfile')
            .with_content(%r{os\.region = 'IAD'$})
            .with_content(%r{os\.openstack_network_url = 'https://iad\.networks})
            .with_content(%r{os\.openstack_image_url = 'https://iad\.images})
            .with_content(%r{os\.username = 'user'$})
            .with_content(%r{os\.password = 'pass'$})
            .with_content(%r{os\.tenant_name = 'tenant'$})
        end
      end
    end
  end
end
