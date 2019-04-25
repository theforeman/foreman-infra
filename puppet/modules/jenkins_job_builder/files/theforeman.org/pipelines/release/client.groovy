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
                mash('foreman-client-mash-split.py', foreman_version)
            }
        }
        stage('Repoclosure') {
            agent { label 'el' }

            steps {
                script {
                    def parallelStagesMap = [:]
                    def name = 'foreman-client'
                    for (distro in foreman_client_distros) {
                        if (distro.startsWith('el')) {
                            parallelStagesMap[distro] = { repoclosure(name, distro, foreman_version) }
                        } else if (distro.startsWith('fc')) {
                            parallelStagesMap[distro] = { repoclosure(name, distro.replace('fc', 'f'), foreman_version) }
                        }
                    }
                    parallel parallelStagesMap
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
                git url: 'https://github.com/theforeman/foreman-infra', poll: false

                dir('deploy') {
                    withRVM(["bundle install --jobs=5 --retry=5"])
                    script {
                        for (distro in distros) {
                            push_foreman_rpms('client', foreman_version, distro)
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
    }
}
