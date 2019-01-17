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

                sh "ssh -o 'BatchMode yes' root@koji.katello.org foreman-mash-split-plugins.py"

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
                        repoclosure('nightly', 'el7')
                        versions['nightly'] = true
                    } catch(Exception ex) {
                        versions['nightly'] = false
                    }
                }
            }
        }
        stage('repoclosure-1.21-el7') {
            steps {
                script {
                    try {
                        repoclosure('1.21', 'el7')
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
                        repoclosure('1.20', 'el7')
                        versions['1.20'] = true
                    } catch(Exception ex) {
                        versions['1.20'] = false
                    }
                }
            }
        }
        stage('repoclosure-1.19-el7') {
            steps {
                script {
                    try {
                        repoclosure('1.19', 'el7')
                        versions['1.19'] = true
                    } catch(Exception ex) {
                        versions['1.19'] = false
                    }
                }
            }
        }
        stage('repoclosure-1.18-el7') {
            steps {
                script {
                    try {
                        repoclosure('1.18', 'el7')
                        versions['1.18'] = true
                    } catch(Exception ex) {
                        versions['1.18'] = false
                    }
                }
            }
        }
        stage('repoclosure-1.17-el7') {
            steps {
                script {
                    try {
                        repoclosure('1.17', 'el7')
                        versions['1.17'] = true
                    } catch(Exception ex) {
                        versions['1.17'] = false
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
                                sh "exit 1"
                            }
                        }
                    }
                }
                stage('push-1.19-el7') {
                    steps {
                        script {
                            if (versions['1.19']) {
                                push_rpms('1.19', 'el7')
                            } else {
                                sh "exit 1"
                            }
                        }
                    }
                }
                stage('push-1.18-el7') {
                    steps {
                        script {
                            if (versions['1.18']) {
                                push_rpms('1.18', 'el7')
                            } else {
                                sh "exit 1"
                            }
                        }
                    }
                }
                stage('push-1.17-el7') {
                    steps {
                        script {
                            if (versions['1.17']) {
                                push_rpms('1.17', 'el7')
                            } else {
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

        withRVM(["cap yum repo:sync -S overwrite=false -S merge=true -S repo_source=foreman-plugins-${version}/${os} -S repo_dest=plugins/${version}/${distro}"])

    }

}

void repoclosure(repo, dist, additions = []) {

    node('el') {
        def git_branch = (repo == 'nightly') ? 'develop' : repo

        git url: "https://github.com/theforeman/foreman-packaging", branch: "rpm/${git_branch}", poll: false

        def os_ver = 'RHEL/7'

        if (dist == 'f24') {
            os_ver = 'Fedora/24'
        }

        def command = [
            "./repoclosure.sh yum_${dist}.conf",
            "http://koji.katello.org/releases/yum/foreman-plugins-${repo}/${os_ver}/x86_64/",
            "-l ${dist}-foreman-${repo}",
            "-l ${dist}-foreman-rails-${repo}",
            "-l ${dist}-base",
            "-l ${dist}-updates",
            "-l ${dist}-epel",
            "-l ${dist}-extras",
            "-l ${dist}-scl",
            "-l ${dist}-scl-sclo",
            "-l ${dist}-puppet-5"
        ]

        command = command + additions

        dir('repoclosure') {
            sh command.join(" ")
        }

        deleteDir()
    }

}
