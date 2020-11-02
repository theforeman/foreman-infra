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
                mash('foreman', 'nightly')
            }
        }
        stage('Repoclosure') {
            agent { label 'el' }

            steps {
                script {
                    parallel repoclosures('foreman', foreman_el_releases, foreman_version)
                }
            }
            post {
                always {
                    deleteDir()
                }
            }
        }
        stage('Install Test') {
            agent { label 'el' }

            steps {
                script {
                    def rpm_pipelines = ['install': ['centos7', 'centos8'], 'upgrade': ['centos7', 'centos8']]
                    runCicoPipelines('foreman', foreman_version, rpm_pipelines)
                }
            }
        }
        stage('Push RPMs') {
            agent { label 'admin && sshkey' }
            steps {
                script {
                    push_foreman_rpms(nil, foreman_version, foreman_el_releases)
                }
            }
        }
    }
    post {
        failure {
            notifyDiscourse(env, 'Foreman RPM nightly pipeline failed:', currentBuild.description)
        }
    }
}

