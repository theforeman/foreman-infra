pipeline {
    agent none

    environment {
        foreman_version = "1.22"
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

                mash("katello-mash-split.py", "3.12")

            }
        }
        stage('Katello Repoclosure') {
            agent { label 'el' }

            steps {

                repoclosure('katello', 'el7', env.foreman_version)

            }
        }
        stage('Test Suites') {
            steps {
                script {
                    runCicoJobsInParallel([
                        ['name': 'Install test', 'job': 'foreman-katello-3.12-test'],
                        ['name': 'Upgrade test', 'job': 'foreman-katello-upgrade-3.12-test']
                    ])
                }
            }
        }
        stage('Push RPMs') {
            agent { label 'admin && sshkey' }

            steps {
                push_rpms_katello("3.12")
            }
        }
    }
}
