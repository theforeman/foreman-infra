require 'spec_helper'

describe 'profiles::backup::receiver' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile.with_all_deps }

      context 'with targets' do
        let(:params) do
          {
            targets: ['example01', 'example02']
          }
        end

        it { is_expected.to compile.with_all_deps }
      end
    end
  end
end
