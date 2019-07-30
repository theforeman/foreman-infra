pipeline {
    agent none

    environment {
        foreman_version = "1.23"
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
                mash("foreman-client-mash-split-${foreman_version}.py")
            }
        }
        stage('Repoclosure') {
            agent { label 'el' }
            stages {
                stage('Client Repoclosure') {
                    steps {
                        parallel(
                            'client/el7': { repoclosure('foreman-client', 'el7', env.foreman_version) },
                            'client/el6': { repoclosure('foreman-client', 'el6', env.foreman_version) },
                            'client/el5': { repoclosure('foreman-client', 'el5', env.foreman_version) },
                            'client/fc29': { repoclosure('foreman-client', 'f29', env.foreman_version) },
                            'client/fc28': { repoclosure('foreman-client', 'f28', env.foreman_version) }
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
                    push_foreman_rpms('client', env.foreman_version, 'el7')
                    push_foreman_rpms('client', env.foreman_version, 'el6')
                    push_foreman_rpms('client', env.foreman_version, 'el5')
                    push_foreman_rpms('client', env.foreman_version, 'fc29')
                    push_foreman_rpms('client', env.foreman_version, 'fc28')
                    push_foreman_rpms('client', env.foreman_version, 'sles12')
                    push_foreman_rpms('client', env.foreman_version, 'sles11')
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
