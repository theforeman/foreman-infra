def setup_nightly_build_environment(args) {
    def package_name = args.package_name ?: args.github_repo.tokenize('/').last() // optional
    def ruby_version = args.ruby_version ?: env.ruby_version // optional
    def commit_hash = ''

    dir(package_name) {
        git(url: "https://github.com/${args.github_repo}.git", branch: 'develop')
        commit_hash = archive_git_hash()
    }
    dir('foreman-packaging') { git(url: 'https://github.com/theforeman/foreman-packaging.git', branch: 'rpm/develop') }
    setup_obal()
    configureRVM(ruby_version)

    return commit_hash
}

def generate_nightly_sourcefiles(args) {
    def sourcefile_paths = []

    dir(args.package_name) {
        withRVM(["bundle install --jobs 5 --retry 5"], env.ruby_version)
        withRVM(["bundle exec rake pkg:generate_source"], env.ruby_version)
        archiveArtifacts(artifacts: 'pkg/*')
        dir('pkg') {
            sourcefile_paths = sh(script: "ls -1", returnStdout: true).trim().tokenize('\n').collect {
                "${pwd()}/${it}"
            }
        }
    }

    return sourcefile_paths
}
