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
        stage("test ruby-2.0.0 & puppet-3.8.0") {
            steps {
                run_test(ruby: '2.0.0', puppet: '3.8.0')
            }
        }
        stage("test ruby-2.1 & puppet-3.8.0") {
            steps {
                run_test(ruby: '2.1', puppet: '3.8.0')
            }
        }
        stage("test ruby-2.1 & puppet-4.10.9") {
            steps {
                run_test(ruby: '2.1', puppet: '4.10.9')
            }
        }
        stage("test ruby-2.3 & puppet-4.10.9") {
            steps {
                run_test(ruby: '2.3', puppet: '4.10.9')
            }
        }
        stage("test ruby-2.4 & puppet-4.10.9") {
            steps {
                run_test(ruby: '2.4', puppet: '4.10.9')
            }
        }
        stage("test ruby-2.4 & puppet-5.3.3") {
            steps {
                run_test(ruby: '2.4', puppet: '5.3.3')
            }
        }
        stage("test ruby-2.5 & puppet-4.10.9") {
            steps {
                run_test(ruby: '2.5', puppet: '4.10.9')
            }
        }
        stage("test ruby-2.5 & puppet-5.3.3") {
            steps {
                run_test(ruby: '2.5', puppet: '5.3.3')
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
        withRVM(["cp config/settings.yml.example config/settings.yml"], ruby, gemset)
        withRVM(["PUPPET_VERSION='${puppet}' bundle install --without=development --jobs=5 --retry=5"], ruby, gemset)
        withRVM(["PUPPET_VERSION='${puppet}' bundle exec rake jenkins:unit --trace"], ruby, gemset)
    } finally {
        cleanupRVM(ruby, gemset)
        junit(testResults: 'jenkins/reports/unit/*.xml')
    }
}
