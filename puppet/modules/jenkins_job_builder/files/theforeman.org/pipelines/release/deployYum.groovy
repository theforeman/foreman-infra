pipeline {
    agent { label 'admin && sshkey' }

    option {
        timestamps()
        timeout(time: 30, unit: 'MINUTES')
        disableConcurrentBuilds()
        ansiColor('xterm')
    }

    stages {
        stage("Setup Push Environment") {
            steps {
                git url: 'https://github.com/theforeman/foreman-infra'
                dir('deploy') { withRVM(["bundle install"]) }

                if (env.getProperty('os') =~ /f\d+/) {
                    env.setProperty('osname', 'Fedora')
                } else {
                    env.setProperty('osname', 'RHEL')
                }
                osver = (env.getProperty('os') =~ /\d+/)[0][0]
            }
        }

        stage("Push RPMs") {
            steps {
                dir('deploy') {
                    withRVM(["cap yum repo:sync -S overwrite=${overwrite} -S merge=${merge} -S repo_source=${repo_source}/${osname}/${osver} -S repo_dest=${repo_dest}/${os}"])
                }
            }
        }
    }
    post {
        always {
            deleteDir()
        }
    }
}
