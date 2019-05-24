def versions = [:]

pipeline {
    agent { label 'admin && sshkey' }

    options {
        timestamps()
        timeout(time: 2, unit: 'HOURS')
        disableConcurrentBuilds()
        ansiColor('xterm')
    }

    stages {
        stage('Mash Koji Repositories') {
            steps {

                mash("foreman-mash-split-plugins.py")

            }
        }
        stage('Setup Push Environment') {
            steps {

                git_clone_foreman_infra()
                dir('deploy') { withRVM(["bundle install --jobs=5 --retry=5"]) }

            }
        }
        stage('repoclosure-nightly-el7') {
            steps {
                script {
                    try {
                        repoclosure('plugins', 'el7', 'nightly')
                        versions['nightly'] = true
                    } catch(Exception ex) {
                        versions['nightly'] = false
                    }
                }
            }
        }
        stage('repoclosure-1.22-el7') {
            steps {
                script {
                    try {
                        repoclosure('plugins', 'el7', '1.22')
                        versions['1.22'] = true
                    } catch(Exception ex) {
                        versions['1.22'] = false
                    }
                }
            }
        }
        stage('repoclosure-1.21-el7') {
            steps {
                script {
                    try {
                        repoclosure('plugins', 'el7', '1.21')
                        versions['1.21'] = true
                    } catch(Exception ex) {
                        versions['1.21'] = false
                    }
                }
            }
        }
        stage('repoclosure-1.20-el7') {
            steps {
                script {
                    try {
                        repoclosure('plugins', 'el7', '1.20')
                        versions['1.20'] = true
                    } catch(Exception ex) {
                        versions['1.20'] = false
                    }
                }
            }
        }
        stage('push-rpms') {
            parallel {
                stage('push-nightly-el7') {
                    steps {
                        script {
                            if (versions['nightly']) {
                                push_rpms('nightly', 'el7')
                            } else {
                                sh "echo nightly el7 repoclosure failed"
                                sh "exit 1"
                            }
                        }
                    }
                }
                stage('push-1.22-el7') {
                    steps {
                        script {
                            if (versions['1.22']) {
                                push_rpms('1.22', 'el7')
                            } else {
                                sh "echo 1.22 el7 repoclosure failed"
                                sh "exit 1"
                            }
                        }
                    }
                }
                stage('push-1.21-el7') {
                    steps {
                        script {
                            if (versions['1.21']) {
                                push_rpms('1.21', 'el7')
                            } else {
                                sh "echo 1.21 el7 repoclosure failed"
                                sh "exit 1"
                            }
                        }
                    }
                }
                stage('push-1.20-el7') {
                    steps {
                        script {
                            if (versions['1.20']) {
                                push_rpms('1.20', 'el7')
                            } else {
                                sh "echo 1.20 el7 repoclosure failed"
                                sh "exit 1"
                            }
                        }
                    }
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

void push_rpms(version, distro) {
    def os = 'RHEL/7'

    dir('deploy') {

        if (distro == 'f24') {
            os = 'Fedora/24'
        }

        push_rpms_direct("foreman-plugins-${version}/${os}", "plugins/${version}/${distro}", false, true)

    }

}
