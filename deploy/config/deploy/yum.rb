set :application, "yum.theforeman.org"
set :user_sudo, false

# parameters, use cap -S
set :host, fetch(:host, "web02.theforeman.org")
#set :repo_source, "foreman-nightly/RHEL/6"
#set :repo_dest, "nightly/el6"
set :overwrite, fetch(:overwrite, false)
set :merge, fetch(:merge, false)

set :repo_source_base, "rsync://koji.katello.org/releases"
set :repo_source_rpm, "#{repo_source_base}/yum/#{repo_source}"
set :repo_source_srpm, "#{repo_source_base}/source/#{repo_source}"

set :deploy_to, "/var/www/vhosts/yum/htdocs"
set :repo_path, "#{deploy_to}/#{repo_dest}"
# hidden directory
set :repo_instance_path, "#{deploy_to}/#{File.dirname(repo_dest)}/.#{File.basename(repo_dest)}-#{Time.now.utc.strftime("%Y%m%d%H%M%S")}"

set :repo_rsync_log, "/tmp/rsync-#{repo_dest.gsub('/', '-')}-#{Time.now.utc.strftime("%Y%m%d%H%M%S")}.log"

role :web, host

ssh_options[:forward_agent] = true

if File.exists?(".CAPUSER")
  set :user, File.open(".CAPUSER", "r").read.chomp
else
  set :user, "root"
end

namespace :repo do
  task :sync do
    prepcache
    rsync
    replace
    purgecdn
  end

  # Copy with hard links the existing repo to minimise rsync later
  task :prepcache do
    unless overwrite || merge || capture("test -e #{repo_path} && echo yes || true").empty?
      raise CommandError.new("Repo overwrite (#{overwrite}) or merge (#{merge}) are disabled, but #{repo_path} already exists")
    end
    run "if [ -e #{repo_path} ]; then cp -al #{repo_path} #{repo_instance_path}; else mkdir -p #{repo_instance_path}; fi"
  end

  task :rsync do
    opts = merge ? '--exclude=**/repodata/' : '--delete'
    opts << ' -avH'
    opts << " --log-file #{repo_rsync_log}"
    run "rsync #{opts} --log-file-format 'CHANGED %f' #{repo_source_rpm}/* #{repo_instance_path}/"
    run "rsync #{opts} --log-file-format 'CHANGED source/%f' #{repo_source_srpm}/ #{repo_instance_path}/source/"
    run %Q{for d in #{repo_instance_path}/*; do (cd $d; latest=$(ls -t foreman-release-[0-9]*.rpm 2>/dev/null | head -n1); [ -n "$latest" ] && ln -sf $latest foreman-release.rpm || true); done}
    run %Q{for d in #{repo_instance_path}/*; do (cd $d; latest=$(ls -t foreman-client-release-[0-9]*.rpm 2>/dev/null | head -n1); [ -n "$latest" ] && ln -sf $latest foreman-client-release.rpm || true); done}
    run %Q{for d in #{repo_instance_path}/*; do (cd $d; createrepo --skip-symlinks --update .); done} if merge
  end

  task :replace do
    transaction do
      on_rollback do
        run "if [ ! -e #{repo_instance_path} ]; then mv #{repo_path} #{repo_instance_path}; fi"
        run "if [ -e #{repo_instance_path}-previous ]; then mv #{repo_instance_path}-previous #{repo_path}; fi"
      end

      run "if [ -e #{repo_path} ]; then mv #{repo_path} #{repo_instance_path}-previous; fi"
      run "mv #{repo_instance_path} #{repo_path}"
      run "if [ -e #{repo_instance_path}-previous ]; then rm -rf #{repo_instance_path}-previous; fi" if overwrite || merge
    end
  end

  task :purgecdn do
    run %Q{awk '/ CHANGED /{print "https://yum.theforeman.org/#{repo_dest}/"$5}' #{repo_rsync_log} | xargs --no-run-if-empty curl --silent -X PURGE -H 'Fastly-Soft-Purge:1'}
    run %Q{for d in #{repo_instance_path}/*; do purge_base="https://yum.theforeman.org/#{repo_dest}/$(basename $d)"; curl --silent -X PURGE -H 'Fastly-Soft-Purge:1' $purge_base/foreman-release.rpm $purge_base/foreman-client-release.rpm; done}
    run "rm -f #{repo_rsync_log}"
  end
end
