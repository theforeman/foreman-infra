pipeline {
    agent { label 'admin && sshkey' }

    options {
        timestamps()
        timeout(time: 30, unit: 'MINUTES')
        disableConcurrentBuilds()
        ansiColor('xterm')
    }

    stages {
        stage("Setup Push Environment") {
            steps {
                git_clone_foreman_infra()
                dir('deploy') { withRVM(["bundle install --jobs=5 --retry=5"]) }

                script {
                    if (env.getProperty('os') =~ /f\d+/) {
                        env.setProperty('osname', 'Fedora')
                    } else {
                        env.setProperty('osname', 'RHEL')
                    }
                    env.setProperty('osver', (env.getProperty('os') =~ /\d+/)[0][0])
                }
            }
        }

        stage("Push RPMs") {
            steps {
                dir('deploy') {
                    push_rpms_direct("${repo_source}/${osname}/${osver}", "${repo_dest}/${os}", overwrite, merge)
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
