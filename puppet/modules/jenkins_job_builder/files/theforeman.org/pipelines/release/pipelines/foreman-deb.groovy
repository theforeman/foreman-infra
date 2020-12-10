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
            agent any

            steps {
                script {
                    def deb_pipelines = ['install': ['debian10', 'ubuntu1804'], 'upgrade': ['debian10', 'ubuntu1804']]
                    runCicoPipelines('foreman', foreman_version, deb_pipelines)
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
