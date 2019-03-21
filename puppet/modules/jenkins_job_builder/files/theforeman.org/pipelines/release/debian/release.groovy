pipeline {
    agent none

    options {
        timestamps()
        timeout(time: 30, unit: 'MINUTES')
        disableConcurrentBuilds()
        ansiColor('xterm')
    }

    stages {
        stage('Deploy') {
            agent { label 'debian' }
            steps {
                parallel(
                    "stretch": { push_debs_direct('stretch', major_version) },
                    "xenial": { push_debs_direct('xenial', major_version) },
                    "bionic": { push_debs_direct('bionic', major_version) }
                )
            }
        }
    }
}
