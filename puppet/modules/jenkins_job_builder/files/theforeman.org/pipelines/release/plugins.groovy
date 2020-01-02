pipeline {
    agent none

    options {
        timestamps()
        timeout(time: 2, unit: 'HOURS')
        disableConcurrentBuilds()
        ansiColor('xterm')
    }

    stages {
        stage('Mash Koji Repositories') {
            agent { label 'sshkey' }

            steps {
                mash('foreman-plugins', foreman_version)
            }
        }
        stage('Repoclosure') {
            agent { label 'el' }
            steps {
                // TODO: from variables
                repoclosure('plugins', 'el7', foreman_version)
            }
            post {
                always {
                    deleteDir()
                }
            }
        }
        stage('Push RPMs') {
            agent { label 'admin && sshkey' }
            steps {
                git_clone_foreman_infra()
                dir('deploy') {
                    withRVM(["bundle install --jobs=5 --retry=5"])
                    // TODO: from variables
                    push_rpms_direct("foreman-plugins-${foreman_version}/RHEL/7", "plugins/${foreman_version}/el7", false, true)
                }
            }
            post {
                always {
                    deleteDir()
                }
            }
        }
    }
}
