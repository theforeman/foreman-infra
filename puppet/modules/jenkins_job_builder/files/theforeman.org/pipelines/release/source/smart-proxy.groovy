def commit_hash = ''
foreman_branch = 'develop'
project_name = 'smart-proxy'
source_type = 'rake'

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
                git(url: 'https://github.com/theforeman/smart-proxy', branch: 'develop')
                script {
                    commit_hash = archive_git_hash()
                }
            }
        }
        stage("test ruby-2.0") {
            steps {
                run_test(ruby: '2.0.0')
            }
        }
        stage("test ruby-2.3") {
            steps {
                run_test(ruby: '2.3')
            }
        }
        stage("test ruby-2.5") {
            steps {
                run_test(ruby: '2.5')
            }
        }
        stage("test ruby-2.6") {
            steps {
                run_test(ruby: '2.6')
            }
        }
        stage('Build and Archive Source') {
            steps {
                dir(project_name) {
                    git url: "https://github.com/theforeman/${project_name}", branch: foreman_branch
                }
                script {
                    sourcefile_paths = generate_sourcefiles(project_name: project_name, source_type: source_type)
                }
            }
        }
        stage('Build Packages') {
            steps {
                build(
                    job: "${project_name}-${foreman_branch}-package-release",
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
    def gemset = "ruby-${ruby}"

    try {
        configureRVM(ruby, gemset)
        withRVM(["cp config/settings.yml.example config/settings.yml"], ruby, gemset)
        withRVM(["bundle install --without=development --jobs=5 --retry=5"], ruby, gemset)
        withRVM(["bundle exec rake jenkins:unit --trace"], ruby, gemset)
    } finally {
        cleanupRVM(ruby, gemset)
        junit(testResults: 'jenkins/reports/unit/*.xml')
    }
}
