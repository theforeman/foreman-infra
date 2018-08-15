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
        stage('Install Test') {
            agent { label 'el' }

            steps {
                git url: 'https://github.com/theforeman/foreman-infra'

                withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'jenkins-centos', passwordVariable: 'PASSWORD', usernameVariable: 'USERNAME']]) {
                    runPlaybook(
                        playbook: 'ci/centos.org/ansible/jenkins_job.yml',
                        extraVars: ["jenkins_job_name=foreman-katello-nightly-test", "jenkins_username=${env.USERNAME}", "jenkins_password=${env.PASSWORD}"],
                        options: ['-b']
                    )
                }
            }
        }
        stage('Push RPMs') {
            agent { label 'admin && sshkey' }

            steps {
                git url: 'https://github.com/theforeman/foreman-infra'

                dir('deploy') {
                    withRVM(["bundle install --jobs=5 --retry=5"])
                    withRVM(["cap yum repo:sync -S overwrite=true -S merge=false -S repo_source=foreman-client-nightly/el7 -S repo_dest=client/el7"])
                    withRVM(["cap yum repo:sync -S overwrite=true -S merge=false -S repo_source=foreman-client-nightly/el6 -S repo_dest=client/el6"])
                    withRVM(["cap yum repo:sync -S overwrite=true -S merge=false -S repo_source=foreman-client-nightly/el5 -S repo_dest=client/el5"])
                    withRVM(["cap yum repo:sync -S overwrite=true -S merge=false -S repo_source=foreman-client-nightly/fc27 -S repo_dest=client/fc27"])
                    withRVM(["cap yum repo:sync -S overwrite=true -S merge=false -S repo_source=foreman-client-nightly/fc28 -S repo_dest=client/fc28"])
                    withRVM(["cap yum repo:sync -S overwrite=true -S merge=false -S repo_source=foreman-client-nightly/sles11 -S repo_dest=client/sles11"])
                    withRVM(["cap yum repo:sync -S overwrite=true -S merge=false -S repo_source=foreman-client-nightly/sles12 -S repo_dest=client/sles12"])
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

void repoclosure(repo, dist) {
    obal(
        action: 'repoclosure',
        packages: "${repo}-repoclosure-${dist}"
    )
}
