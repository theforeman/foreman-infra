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
                mash('foreman-client', foreman_version)
            }
        }
        stage('Repoclosure') {
            agent { label 'el' }

            steps {
                script {
                    def parallelStagesMap = [:]
                    def name = 'foreman-client'
                    foreman_client_distros.each { distro ->
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
                script {
                    push_foreman_rpms('client', foreman_version, foreman_client_distros)
                }
            }
        }
    }
}
