def commit_hash = ''

pipeline {
    agent any

    options {
        timestamps()
        timeout(time: 2, unit: 'HOURS')
        ansiColor('xterm')
    }

    stages {
        stage("Collect Git Hash") {
            steps {
                git(url: 'https://github.com/theforeman/hammer-cli', branch: 'master')
                script {
                    commit_hash = archive_git_hash()
                }
            }
        }
        stage("test-ruby-2.3") {
            steps {
                run_test(ruby: '2.3')
            }
        }
        stage("test-ruby-2.4") {
            steps {
                run_test(ruby: '2.4')
            }
        }
        stage("test-ruby-2.5") {
            steps {
                run_test(ruby: '2.5')
            }
        }
        stage("Release Nightly Package") {
            steps {
                build(
                    job: 'hammer-cli-master-release',
                    propagate: false,
                    wait: false,
                    parameters: [
                        string(name: 'git_ref', value: commit_hash)
                    ]
                )
            }
        }
    }
    post {
        always {
            deleteDir()
        }
    }
}

def run_test(args) {
    def ruby = args.ruby
    def gemset = "ruby-${ruby}"

    try {
        configureRVM(ruby, gemset)
        withRVM(['bundle install --without=development --jobs=5 --retry=5'], ruby, gemset)
        withRVM(['bundle exec rake ci:setup:minitest test TESTOPTS="-v"'], ruby, gemset)
    } finally {
        cleanupRVM(ruby, gemset)
        junit(testResults: 'test/reports/*.xml')
    }
}
