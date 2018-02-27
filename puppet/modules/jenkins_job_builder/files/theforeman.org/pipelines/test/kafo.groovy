pipeline {
    agent none
    options {
        timeout(time: 1, unit: 'HOURS')
    }

    stages {
        stage('Test') {
            matrix {
                agent any
                axes {
                    axis {
                        name 'ruby'
                        values '2.0.0', '2.1', '2.2', '2.3', '2.4', '2.5', '2.6'
                    }
                    axis {
                        name 'PUPPET_VERSION'
                        values '4.10', '5.0', '6.0'
                    }
                }
                excludes {
                    exclude {
                        axis {
                            name 'PUPPET_VERSION'
                            values '5.0', '6.0'
                        }
                        axis {
                            name 'ruby'
                            values '2.0.0', '2.1', '2.2', '2.3'
                        }
                    }
                }
                stages {
                    stage('Setup Git Repos') {
                        steps {
                            ghprb_git_checkout()
                        }
                    }
                    stage("Setup RVM") {
                        steps {
                            configureRVM(ruby)
                        }
                    }
                    stage('Install dependencies') {
                        steps {
                            withRVM(['bundle install'], ruby)
                        }
                    }
                    stage('Run Tests') {
                        steps {
                            withRVM(['bundle exec rake jenkins:unit TESTOPTS="-v" --trace'], ruby)
                        }
                    }
                }
                post {
                    always {
                        archiveArtifacts artifacts: "Gemfile.lock"
                        junit keepLongStdio: true, testResults: 'jenkins/reports/unit/*.xml'
                        cleanupRVM('', ruby)
                        deleteDir()
                    }
                }
            }
        }
    }
}
