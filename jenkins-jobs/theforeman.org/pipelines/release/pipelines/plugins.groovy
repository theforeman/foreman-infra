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
                script {
                    parallel repoclosures('plugins', foreman_el_releases, foreman_version)
                }
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
                script {
                    def overwrite = foreman_version == 'nightly'
                    def merge = foreman_version != 'nightly'
                    for (release in foreman_el_releases) {
                        push_rpms_direct("foreman-plugins-${foreman_version}/RHEL/${release.replace('el', '')}", "plugins/${foreman_version}/${release}", overwrite, merge)
                    }
                }
            }
        }
    }
}
