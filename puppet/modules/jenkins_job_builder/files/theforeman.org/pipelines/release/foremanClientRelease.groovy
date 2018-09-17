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

                sh "ssh -o 'BatchMode yes' root@koji.katello.org foreman-client-mash-split.py"

            }
        }
        stage('Clone packaging') {
            agent { label 'el' }
            steps {
                git url: "https://github.com/theforeman/foreman-packaging", branch: "rpm/develop"
            }
        }
        stage('Repoclosure') {
            agent { label 'el' }
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
        stage('Push RPMs') {
            agent { label 'admin && sshkey' }

            steps {
                git url: 'https://github.com/theforeman/foreman-infra'

                dir('deploy') {
                    withRVM(["bundle install --jobs=5 --retry=5"])
                    push_rpms('nightly', 'el7')
                    push_rpms('nightly', 'el6')
                    push_rpms('nightly', 'el5')
                    push_rpms('nightly', 'fc28')
                    push_rpms('nightly', 'fc27')
                    push_rpms('nightly', 'sles12')
                    push_rpms('nightly', 'sles11')
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

void push_rpms(version, distro) {
    withRVM(["cap yum repo:sync -S overwrite=true -S merge=false -S repo_source=foreman-client-${version}/${distro} -S repo_dest=client/${version}/${distro}"])
}

void repoclosure(repo, dist) {
    obal(
        action: 'repoclosure',
        packages: "${repo}-repoclosure-${dist}"
    )
}
