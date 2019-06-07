pipeline {
    agent none

    environment {
        foreman_version = 'develop'
    }

    options {
        timestamps()
        timeout(time: 2, unit: 'HOURS')
        disableConcurrentBuilds()
        ansiColor('xterm')
    }

    stages {
        stage('Mash Koji Repositories') {
            agent { label 'sshkey' }

            steps {
                mash('foreman-mash-split.py')
            }
        }
        stage('Repoclosure') {
            agent { label 'el' }

            steps {

                repoclosure('foreman', 'el7', env.foreman_version)

            }
        }
        stage('Install Test') {
            steps {
                runCicoJob("foreman-nightly-centos7-test")
            }
        }
        stage('Push RPMs') {
            agent { label 'admin && sshkey' }

            steps {
                git_clone_foreman_infra()

                dir('deploy') {

                    withRVM(["bundle install --jobs=5 --retry=5"])
                    push_rpms_direct("foreman-nightly/RHEL/7", "nightly/el7")
                }
            }
            post {
                always {
                    deleteDir()
                }
            }
        }
    }
    post {
        failure {
            notifyDiscourse(env, 'Foreman RPM nightly pipeline failed:', currentBuild.description)
        }
    }
}

