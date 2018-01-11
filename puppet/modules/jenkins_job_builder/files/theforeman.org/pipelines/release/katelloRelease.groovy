pipeline {
    agent none

    triggers {
        cron('H 23 * * *')
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

                sh "ssh -o 'BatchMode yes' root@koji.katello.org katello-mash-split.py"

            }
        }
        stage('Client Repoclosure') {
            steps {

                parallel(
                    'client/el7': { repoclosure('client', 'el7') },
                    'client/el6': { repoclosure('client', 'el6') },
                    'client/fc25': { repoclosure('client', 'f25') },
                    'client/fc26': { repoclosure('client', 'f26') }
                )

            }
        }
        stage('Pulp Repoclosure') {
            agent { label 'el' }

            steps {

                repoclosure('pulp', 'el7')

            }
        }
        stage('Candlepin Repoclosure') {
            agent { label 'el' }

            steps {

                repoclosure('candlepin', 'el7')

            }
        }
        stage('Katello Repoclosure') {
            agent { label 'el' }

            steps {

              repoclosure('katello', 'el7')

            }
        }
        stage('Install Test') {
            agent { label 'el' }

            environment {
                VAGRANT_DEFAULT_PROVIDER = 'rackspace'
            }
            steps {

                git url: 'https://github.com/theforeman/forklift'

                sh "cp -f boxes.d/99-local.yaml.example boxes.d/99-local.yaml"
                sh "vagrant up centos7-katello-bats-ci"

            }
            post {
                always {
                    sh "mkdir debug"
                    sh "vagrant ssh-config centos7-katello-bats-ci > ssh_config"

                    sh "scp -F ssh_config centos7-katello-bats-ci:/root/bats_results/*.tap debug/ || true"
                    sh "scp -F ssh_config centos7-katello-bats-ci:/root/last_logs debug/ || true"
                    sh "scp -F ssh_config centos7-katello-bats-ci:/root/sosreport* debug/ || true"
                    sh "scp -F ssh_config centos7-katello-bats-ci:/root/foreman-debug.tar.xz debug/ || true"
                    sh "scp -F ssh_config centos7-katello-bats-ci:/var/log/foreman-installer/katello.log debug/ || true"

                    sh "vagrant destroy centos7-katello-bats-ci"

                    archive "debug/*"
                    script { step([$class: "TapPublisher", testResults: "debug/*.tap"]) }
                    deleteDir()
                }
            }
        }
        stage('Push RPMs') {
            agent { label 'admin && sskey' }

            steps {

                sh "ssh -i /var/lib/workspace/workspace/deploy_katello_repos_key/deploy_katello_repos_key katelloproject@fedorapeople.org \"cd /project/katello/bin && sh rsync-repos-from-koji nightly\""

            }
        }
    }
}

void repoclosure(repo, dist, additions = []) {

    node('el') {
        git url: "http://github.com/theforeman/foreman-packaging", branch: "rpm/develop"

        def command = [
            "./repoclosure.sh yum_${dist}.conf",
            "http://koji.katello.org/releases/yum/katello-nightly/${repo}/${dist}/x86_64/",
            "-l ${dist}-foreman-nightly",
            "-l ${dist}-foreman-plugins-nightly",
            "-l ${dist}-base",
            "-l ${dist}-updates",
            "-l ${dist}-epel",
            "-l ${dist}-extras",
            "-l ${dist}-scl",
            "-l ${dist}-scl-sclo",
            "-l ${dist}-scl-ruby",
            "-l ${dist}-scl-v8",
            "-l ${dist}-tfm-ror51",
            "-l ${dist}-puppet-3",
            "-l ${dist}-puppet-4",
            "-l ${dist}-subscription-manager",
            "-l ${dist}-qpid",
            "-l ${dist}-katello-pulp-nightly",
            "-l ${dist}-katello-candlepin-nightly"
        ]

        command = command + additions

        dir('repoclosure') {
            sh command.join(" ")
        }

        deleteDir()
    }

}

