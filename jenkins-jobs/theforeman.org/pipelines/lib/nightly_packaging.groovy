def generate_sourcefiles(args) {
    def sourcefile_paths = []
    def project_name = args.project_name
    def ruby_version = args.ruby_version ?: '2.5'
    def source_type = args.source_type

    dir(project_name) {

        echo source_type
        if (source_type == 'gem') {
            withRVM(["gem build *.gemspec"], ruby_version)
            sourcefiles = list_files('./').findAll { "${it}".endsWith('.gem') }
            archiveArtifacts(artifacts: sourcefiles.join(','))
            sourcefile_paths = sourcefiles.collect { "${pwd()}/${it}" }
        } else {
            try {
                configureRVM(ruby_version)
                withRVM(["bundle install --jobs 5 --retry 5"], ruby_version)
                withRVM(["bundle exec rake pkg:generate_source"], ruby_version)
                archiveArtifacts(artifacts: 'pkg/*')
                sourcefile_paths = list_files('pkg/').collect {
                    "${pwd()}/pkg/${it}"
                }
            } finally {
                cleanupRVM(ruby_version)
            }
        }
    }

    return sourcefile_paths
}
