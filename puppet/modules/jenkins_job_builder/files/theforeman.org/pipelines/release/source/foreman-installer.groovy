pipeline {
    agent any

    options {
        timestamps()
        timeout(time: 2, unit: 'HOURS')
        ansiColor('xterm')
        buildDiscarder(logRotator(daysToKeepStr: '7'))
    }

    stages {
        stage("Collect Git Hash") {
            steps {
                git url: git_url, branch: git_ref
                script {
                    archive_git_hash()
                }
            }
        }
        stage("test ruby 2.5 & puppet 6") {
            steps {
                run_test(ruby: '2.5', puppet: '6.3')
            }
        }
        stage('Build and Archive Source') {
            steps {
                dir(project_name) {
                    git url: git_url, branch: git_ref
                }
                script {
                    sourcefile_paths = generate_sourcefiles(project_name: project_name, source_type: source_type)
                }
            }
        }
    }
    post {
        success {
            build(
                job: "${project_name}-${git_ref}-package-release",
                propagate: false,
                wait: false
            )
        }

        failure {
            notifyDiscourse(env, "${project_name} source release pipeline failed:", currentBuild.description)
        }

        always {
            deleteDir()
        }
    }
}

def run_test(args) {
    def ruby = args.ruby
    def puppet = args.puppet
    def gemset = "ruby-${ruby}-puppet-${puppet}"

    try {
        configureRVM(ruby, gemset)
        withRVM(["PUPPET_VERSION='${puppet}' bundle install --without=development --jobs=5 --retry=5"], ruby, gemset)
        withRVM(["PUPPET_VERSION='${puppet}' bundle exec rake spec"], ruby, gemset)
    } finally {
        cleanupRVM(ruby, gemset)
    }
}
