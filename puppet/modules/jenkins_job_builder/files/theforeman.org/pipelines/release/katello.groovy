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

                repoclosure('katello', 'el7', foreman_version)

            }
        }
        stage('Test Suites') {
            agent { label 'el' }

            steps {
                script {
                    runCicoJobsInParallel([
                        ['name': 'Install test', 'job': "foreman-katello-${katello_version}-test"],
                        ['name': 'Upgrade test', 'job': "foreman-katello-upgrade-${katello_version}-test"]
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
