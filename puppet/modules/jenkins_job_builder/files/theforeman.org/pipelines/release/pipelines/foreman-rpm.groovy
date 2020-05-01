pipeline {
    agent none

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
                mash('foreman', 'nightly')
            }
        }
        stage('Repoclosure') {
            agent { label 'el' }

            steps {
                script {
                    parallel repoclosures('foreman', foreman_el_releases, foreman_version)
                }
            }
            post {
                always {
                    deleteDir()
                }
            }
        }
        stage('Install Test') {
            agent { label 'el' }

            steps {
                script {
                    runCicoJobsInParallel([
                        ['name': 'centos7', 'job': 'foreman-nightly-centos7-test'],
                        ['name': 'centos7-upgrade', 'job': 'foreman-nightly-centos7-upgrade-test'],
                        ['name': 'centos8', 'job': 'foreman-nightly-centos8-test']
                    ])
                }
            }
        }
        stage('Push RPMs') {
            agent { label 'admin && sshkey' }

            steps {
                git_clone_foreman_infra()

                dir('deploy') {

                    withRVM(["bundle install --jobs=5 --retry=5"])
                    push_rpms_direct("foreman-nightly/RHEL/7", "nightly/el7")
                    push_rpms_direct("foreman-nightly/RHEL/8", "nightly/el8")
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

