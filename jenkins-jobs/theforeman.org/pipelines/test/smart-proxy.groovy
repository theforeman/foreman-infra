pipeline {
    agent none
    options {
        timeout(time: 1, unit: 'HOURS')
        ansiColor('xterm')
    }
    environment {
        BUNDLE_JOBS = 4
        BUNDLE_RETRY = 3
    }

    stages {
        stage('Rubocop') {
            agent any
            environment {
                BUNDLE_WITHOUT = 'bmc:development:dhcp_isc_inotify:dhcp_isc_kqueue:journald:krb5:libvirt:puppetca_token_whitelisting:realm_freeipa:windows'
            }

            stages {
                stage('Setup Git Repos') {
                    steps {
                        ghprb_git_checkout()
                    }
                }
                stage('Setup RVM') {
                    steps {
                        configureRVM('2.7')
                    }
                }
                stage('Install dependencies') {
                    steps {
                        withRVM(['bundle install'], '2.7')
                    }
                }
                stage('Run Rubocop') {
                    steps {
                        withRVM(['bundle exec rubocop --format progress --out rubocop.log --format progress'], '2.7')
                    }
                    post {
                        always {
                            recordIssues tool: ruboCop(pattern: 'rubocop.log'), enabledForFailure: true
                        }
                    }
                }
            }
            post {
                always {
                    cleanupRVM('2.7')
                    deleteDir()
                }
            }
        }

        stage('Test') {
            matrix {
                agent any
                axes {
                    axis {
                        name 'ruby'
                        values '2.5', '2.6', '2.7'
                    }
                }
                environment {
                    BUNDLE_WITHOUT = 'development'
                }
                stages {
                    stage('Setup Git Repos') {
                        steps {
                            ghprb_git_checkout()
                        }
                    }
                    stage('Setup RVM') {
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
                            withRVM(['bundle exec rake jenkins:unit'], ruby)
                        }
                        post {
                            always {
                                junit testResults: 'jenkins/reports/unit/*.xml'
                            }
                        }
                    }
                }
                post {
                    always {
                        archiveArtifacts artifacts: 'Gemfile.lock'
                        cleanupRVM(ruby)
                        deleteDir()
                    }
                }
            }
        }
    }
}
