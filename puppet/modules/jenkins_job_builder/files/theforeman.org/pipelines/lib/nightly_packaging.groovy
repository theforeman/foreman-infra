def setup_nightly_build_environment(args) {
    def commit_hash = ''
    def project_name = args.project_name
    def git_url = args.git_url
    def branch = args.branch
    def ruby_version = args.ruby_version ?: env.ruby_version

    dir(project_name) {
        git(url: git_url, branch: branch)
        commit_hash = archive_git_hash()
    }
    dir('foreman-packaging') {
        git(url: 'https://github.com/theforeman/foreman-packaging.git', branch: 'rpm/develop')
    }
    setup_obal()
    configureRVM(ruby_version)

    return commit_hash
}

def generate_nightly_sourcefiles(args) {
    def sourcefile_paths = []
    def project_name = args.project_name
    def ruby_version = args.ruby_version ?: env.ruby_version

    dir(project_name) {
        withRVM(["bundle install --jobs 5 --retry 5"], ruby_version)
        withRVM(["bundle exec rake pkg:generate_source"], ruby_version)
        archiveArtifacts(artifacts: 'pkg/*')
        sourcefile_paths = list_files('pkg/').collect {
            "${pwd()}/pkg/${it}"
        }
    }

    return sourcefile_paths
}
