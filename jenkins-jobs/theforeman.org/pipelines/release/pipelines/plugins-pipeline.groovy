pipeline {
    agent none

    options {
        timestamps()
        timeout(time: 2, unit: 'HOURS')
        disableConcurrentBuilds()
        ansiColor('xterm')
    }

    stages {
        stage('Install Test') {
            agent any

            steps {
                script {
                    runCicoPipelines('plugins', foreman_version, pipelines)
                }
            }
        }
    }

    post {
        failure {
            notifyDiscourse(env, "Foreman ${foreman_version} Plugins Test pipeline failed:", currentBuild.description)
        }
    }
}
