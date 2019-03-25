pipeline {
    agent none

    options {
        timestamps()
        timeout(time: 2, unit: 'HOURS')
        disableConcurrentBuilds()
        ansiColor('xterm')
    }

    stages {
        stage('Install tests and Upgrade tests') {
            steps {
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
            emailext(
                subject: "${env.JOB_NAME} ${env.BUILD_ID} failed",
                to: 'evgeni@redhat.com',
                body: "Luna nightly pipeline failed: \n\n${env.BUILD_URL}"
            )
        }
    }
}
