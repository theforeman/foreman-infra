pipeline {
    agent none

    options {
        timestamps()
        timeout(time: 3, unit: 'HOURS')
        disableConcurrentBuilds()
        ansiColor('xterm')
    }

    stages {
        stage('Mash Koji Repositories') {
            agent { label 'sshkey' }

            steps {
                mash("katello", katello_version)
            }
        }
        stage('Katello Repoclosure') {
            agent { label 'el' }

            steps {
                script {
                    parallel repoclosures('katello', foreman_el_releases, foreman_version)
                }
            }
            post {
                always {
                    deleteDir()
                }
            }
        }
        stage('Test Suites') {
            agent { label 'el' }

            steps {
                script {
                    runCicoPipelines('katello', katello_version, pipelines)
                }
            }
        }
        stage('Push RPMs') {
            agent { label 'admin && sshkey' }

            steps {
                push_rpms_katello(katello_version)
            }
        }
    }
    post {
        failure {
            notifyDiscourse(env, 'Katello nightly pipeline failed:', currentBuild.description)
        }
    }
}
