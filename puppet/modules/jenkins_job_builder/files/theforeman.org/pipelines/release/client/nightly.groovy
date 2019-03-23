pipeline {
    agent none

    environment {
        version = "nightly"
        branch = "rpm/develop"
    }

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
                mash("foreman-client-mash-split.py")
            }
        }
        stage('Repoclosure') {
            agent { label 'el' }
            stages {
                stage('Set up') {
                    steps {
                        git url: "https://github.com/theforeman/foreman-packaging", branch: env.branch, poll: false
                        setup_obal()
                    }
                }
                stage('Client Repoclosure') {
                    steps {
                        parallel(
                            'client/el7': { repoclosure('foreman-client', 'el7') },
                            'client/el6': { repoclosure('foreman-client', 'el6') },
                            'client/el5': { repoclosure('foreman-client', 'el5') },
                            'client/fc28': { repoclosure('foreman-client', 'f28') },
                            'client/fc27': { repoclosure('foreman-client', 'f27') }
                        )
                    }
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
                    push_foreman_rpms('client', env.version, 'el7')
                    push_foreman_rpms('client', env.version, 'el6')
                    push_foreman_rpms('client', env.version, 'el5')
                    push_foreman_rpms('client', env.version, 'fc28')
                    push_foreman_rpms('client', env.version, 'fc27')
                    push_foreman_rpms('client', env.version, 'sles12')
                    push_foreman_rpms('client', env.version, 'sles11')
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
