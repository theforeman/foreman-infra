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
                            sh "cp Gemfile Gemfile.${ruby}-${PUPPET_VERSION}"
                        }
                    }
                    stage("Setup RVM") {
                        steps {
                            configureRVM(ruby, "${ruby}-${PUPPET_VERSION}")
                        }
                    }
                    stage('Install dependencies') {
                        steps {
                            withRVM(["bundle install --gemfile Gemfile.${ruby}-${PUPPET_VERSION}"], ruby, "${ruby}-${PUPPET_VERSION}")
                        }
                    }
                    stage('Run Tests') {
                        steps {
                            withRVM(["bundle exec rake jenkins:unit TESTOPTS='-v' --trace Gemfile.${ruby}-${PUPPET_VERSION}"], ruby, "${ruby}-${PUPPET_VERSION}")
                        }
                    }
                }
                post {
                    always {
                        archiveArtifacts artifacts: "Gemfile*lock"
                        junit keepLongStdio: true, testResults: 'jenkins/reports/unit/*.xml'
                        cleanupRVM(ruby, "${ruby}-${PUPPET_VERSION}")
                        deleteDir()
                    }
                }
            }
        }
    }
}
