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
                mash('pulpcore', pulpcore_version)
            }
        }
        stage('Repoclosure') {
            agent { label 'el' }

            steps {
                script {
                    def parallelStagesMap = [:]
                    def name = 'pulpcore'
                    pulpcore_distros.each { distro ->
                        parallelStagesMap[distro] = { repoclosure(name, distro, pulpcore_version) }
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
        stage('Test Suites') {
            agent any

            steps {
                script {
                    runCicoPipelines('pulpcore', pulpcore_version, pipelines)
                }
            }
        }
        stage('Push RPMs') {
            agent { label 'admin && sshkey' }

            steps {
                script {
                    pulpcore_distros.each { distro ->
                        push_pulpcore_rpms(pulpcore_version, distro)
                    }
                }
            }
        }
    }
}
