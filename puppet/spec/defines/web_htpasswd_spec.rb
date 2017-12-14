require 'spec_helper'

describe 'web::htpasswd' do
  let :title do
    'username'
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let :facts do
        facts
      end

      let :params do
        {
          :vhost  => 'debugs',
          :passwd => 'secret',
          :salt   => 'salty',
        }
      end

      it { is_expected.to compile.with_all_deps }
      it do
        is_expected.to create_htpasswd('username'). \
          with_target('/var/www/vhosts/debugs/htpasswd'). \
          with_cryptpasswd('saHW9GdxihkGQ')
      end
    end
  end
end
