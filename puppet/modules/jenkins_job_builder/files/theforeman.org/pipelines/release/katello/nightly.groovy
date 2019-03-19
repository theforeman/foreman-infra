pipeline {
    agent none

    environment {
        foreman_version = "develop"
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

                mash("katello-mash-split.py", "nightly")

            }
        }
        stage('Katello Repoclosure') {
            agent { label 'el' }

            steps {

                repoclosure('katello', 'el7', env.foreman_version)

            }
        }
        stage('Install tests and Upgrade tests') {
            steps {
                script {
                    runCicoJobsInParallel([
                        ['name': 'Install test', 'job': 'foreman-katello-nightly-test'],
                        ['name': 'Upgrade test', 'job': 'foreman-katello-upgrade-nightly-test']
                    ])
                }
            }
        }
        stage('Push RPMs') {
            agent { label 'admin && sshkey' }

            steps {
                push_rpms_katello("nightly")
            }
        }
    }
    post {
        failure {
            notifyDiscourse(env, 'Katello nightly pipeline failed:', currentBuild.description)
        }
    }
}
