require 'spec_helper'

describe 'profiles::web' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile.with_all_deps }

      context 'without https' do
        let(:params) { { https: false } }

        it { is_expected.to compile.with_all_deps }
      end
    end
  end
end
