pipeline {
    agent none

    options {
        timestamps()
        timeout(time: 4, unit: 'HOURS')
        disableConcurrentBuilds()
        ansiColor('xterm')
    }

    stages {
        stage('Install tests') {
            agent any

            steps {
                script {
                    runCicoPipelines('foreman', foreman_version, pipelines_deb)
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
