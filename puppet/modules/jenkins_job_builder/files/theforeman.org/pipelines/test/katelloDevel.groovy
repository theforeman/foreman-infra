pipeline {
    agent none

    options {
        timestamps()
        timeout(time: 2, unit: 'HOURS')
        disableConcurrentBuilds()
        ansiColor('xterm')
    }

    stages {
        stage('katello devel forklift pipeline tests') {
            agent { label 'el' }

            steps {
                runCicoJob("foreman-katello-devel-test")
            }
        }
    }
}
