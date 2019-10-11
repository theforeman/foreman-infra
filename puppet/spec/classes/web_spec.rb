require 'spec_helper'

describe 'web' do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      let(:params) { {setup_receiver: false} }

      it { is_expected.to compile.with_all_deps }
    end
  end
end
