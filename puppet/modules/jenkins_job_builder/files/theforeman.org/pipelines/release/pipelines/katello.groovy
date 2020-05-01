pipeline {
    agent none

    options {
        timestamps()
        timeout(time: 3, unit: 'HOURS')
        disableConcurrentBuilds()
        ansiColor('xterm')
    }

    stages {
        stage('Mash Koji Repositories') {
            agent { label 'sshkey' }

            steps {
                mash("katello", katello_version)
            }
        }
        stage('Katello Repoclosure') {
            agent { label 'el' }

            steps {
                script {
                    parallel repoclosures('katello', foreman_el_releases, foreman_version)
                }
            }
            post {
                always {
                    deleteDir()
                }
            }
        }
        stage('Test Suites') {
            agent { label 'el' }

            steps {
                script {
                    runCicoJobsInParallel([
                        ['name': 'centos7 install test', 'job': "foreman-katello-${katello_version}-test"],
                        ['name': 'centos7 upgrade test', 'job': "foreman-katello-upgrade-${katello_version}-test"]
                    ])
                }
            }
        }
        stage('Push RPMs') {
            agent { label 'admin && sshkey' }

            steps {
                push_rpms_katello(katello_version)
            }
        }
    }
}
