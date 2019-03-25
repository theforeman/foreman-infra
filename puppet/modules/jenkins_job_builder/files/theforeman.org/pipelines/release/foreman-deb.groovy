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
            steps {
                script {
                    runCicoJobsInParallel([
                        ['name': 'debian9', 'job': 'foreman-nightly-debian9-test'],
                        ['name': 'ubuntu1604', 'job': 'foreman-nightly-ubuntu1604-test'],
                        ['name': 'ubuntu1804', 'job': 'foreman-nightly-ubuntu1804-test']
                    ])
                }
            }
        }
        stage('Push DEBs') {
            agent { label 'debian' }

            steps {
                parallel(
                    "stretch": { push_debs_direct('stretch', 'nightly') },
                    "xenial": { push_debs_direct('xenial', 'nightly') },
                    "bionic": { push_debs_direct('bionic', 'nightly') }
                )
            }
        }
    }
    post {
        failure {
            emailext(
                subject: "${env.JOB_NAME} ${env.BUILD_ID} failed",
                to: 'ci@community.theforeman.org',
                body: "Foreman DEB nightly pipeline failed: \n\n${env.BUILD_URL}"
            )
        }
    }
}
