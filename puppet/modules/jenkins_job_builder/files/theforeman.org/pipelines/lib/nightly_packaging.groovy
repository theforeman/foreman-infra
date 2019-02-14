def setup_nightly_build_environment(args) {
    def project_name = args.project_name
    def git_url = args.git_url
    def git_ref = args.git_ref
    def ruby_version = args.ruby_version ?: env.ruby_version

    dir(project_name) {
        // the full checkout() is necessary for checking out specific commits,
        // as opposed to just branches with git()
        checkout([
            $class : 'GitSCM',
            branches : [[name: git_ref]],
            extensions: [[$class: 'CleanCheckout']],
            userRemoteConfigs: [[url: git_url]]
        ])
    }
    dir('foreman-packaging') {
        git(url: 'https://github.com/theforeman/foreman-packaging.git', branch: 'rpm/develop', poll: false)
    }
    setup_obal()
    configureRVM(ruby_version)
}

def generate_sourcefiles(args) {
    def sourcefile_paths = []
    def project_name = args.project_name
    def ruby_version = args.ruby_version ?: env.ruby_version
    def source_type = args.source_type

    dir(project_name) {

        echo source_type
        if (source_type == 'gem') {
            withRVM(["gem build *.gemspec"], ruby_version)
            sourcefiles = list_files('./').findAll { "${it}".endsWith('.gem') }
            archiveArtifacts(artifacts: sourcefiles.join(','))
            sourcefile_paths = sourcefiles.collect { "${pwd()}/${it}" }
        } else {
            withRVM(["bundle install --jobs 5 --retry 5"], ruby_version)
            withRVM(["bundle exec rake pkg:generate_source"], ruby_version)
            archiveArtifacts(artifacts: 'pkg/*')
            sourcefile_paths = list_files('pkg/').collect {
                "${pwd()}/pkg/${it}"
            }
        }
    }

    return sourcefile_paths
}
