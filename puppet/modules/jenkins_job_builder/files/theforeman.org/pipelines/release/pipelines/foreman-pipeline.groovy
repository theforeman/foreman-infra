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
                    for (release in foreman_el_releases) {
                        push_rpms_direct("foreman-${foreman_version}/RHEL/${release.replace('el', '')}", "releases/${foreman_version}/${release}", false, true)
                    }
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
        stage('Build container images') {
            agent any

            steps {
                script {
                    def now = createTimestamp()

                    parallel {
                        foreman: {
                            triggerGithubBuilder('foreman', foreman_version, now)
                        },
                        foreman_proxy: {
                            triggerGithubBuilder('foreman_proxy', foreman_version, now)
                        }
                    }
                }

            }
        }
    }
}
