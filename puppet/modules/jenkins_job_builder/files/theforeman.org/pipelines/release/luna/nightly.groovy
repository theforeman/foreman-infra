pipeline {
    agent none

    options {
        timestamps()
        timeout(time: 3, unit: 'HOURS')
        disableConcurrentBuilds()
        ansiColor('xterm')
    }

    stages {
        stage('Install tests and Upgrade tests') {
            steps {
                agent { label 'el' }
                script {
                    runCicoJobsInParallel([
                        ['name': 'Install test', 'job': 'foreman-luna-nightly-test'],
                        ['name': 'Upgrade test', 'job': 'foreman-luna-upgrade-nightly-test']
                    ])
                }
            }
        }
    }
    post {
        failure {
            notifyDiscourse(env, 'Luna nightly pipeline failed:', currentBuild.description)
        }
    }
}
