pipeline {
    agent none

    options {
        timestamps()
        timeout(time: 2, unit: 'HOURS')
        disableConcurrentBuilds()
        ansiColor('xterm')
    }

    stages {
        stage('Install tests') {
            agent { label 'el' }

            steps {
                script {
                    runCicoJobsInParallel([
                        ['name': 'debian10', 'job': 'foreman-nightly-debian10-test'],
                        ['name': 'debian10-upgrade', 'job': 'foreman-nightly-debian10-upgrade-test'],
                        ['name': 'ubuntu1804', 'job': 'foreman-nightly-ubuntu1804-test']
                        ['name': 'ubuntu1804-upgrade', 'job': 'foreman-nightly-ubuntu1804-upgrade-test']
                    ])
                }
            }
        }
        stage('Push DEBs') {
            agent { label 'debian' }

            steps {
                parallel(
                    "buster": { push_debs_direct('buster', 'nightly') },
                    "bionic": { push_debs_direct('bionic', 'nightly') }
                )
            }
        }
    }
    post {
        failure {
            notifyDiscourse(env, 'Foreman DEB nightly pipeline failed:', currentBuild.description)
        }
    }
}
