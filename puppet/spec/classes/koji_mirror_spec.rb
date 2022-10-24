require 'spec_helper'

describe 'koji::mirror' do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      let(:params) {
        {
          servername: 'mirror.example.com',
          mirror_root: '/srv/mirror',
          entitlement_id: '1234567890abcdef',
        }
      }

      it { is_expected.to compile.with_all_deps }
    end
  end
end
