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
                mash("foreman", foreman_version)
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
                    runCicoPipelines('foreman', foreman_version, pipelines, params.expected_version)
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
        stage('Push DEBs') {
            agent { label 'debian' }

            steps {
                script {
                    def pushDistros = [:]
                    foreman_debian_releases.each { distro ->
                        pushDistros["push-${foreman_version}-${distro}"] = {
                            script {
                                push_debs_direct(distro, foreman_version)
                            }
                        }
                    }

                    parallel pushDistros
                }
            }
        }
    }
}
