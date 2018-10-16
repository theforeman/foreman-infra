pipeline {
    agent { label 'rpmbuild' }

    options {
        timestamps()
        timeout(time: 2, unit: 'HOURS')
        ansiColor('xterm')
    }

    stages {
        stage("Setup Environment") {
            steps {
                git(url: 'https://github.com/theforeman/foreman-packaging/')
                setup_obal()
            }
        }

        stage("Obal Release RPM") {
            steps {
                obal(action: 'release', packages: env.project.tokenize('/').last())
            }
        }
    }
}
