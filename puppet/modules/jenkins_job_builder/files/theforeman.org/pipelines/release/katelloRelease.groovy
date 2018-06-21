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

                sh "ssh -o 'BatchMode yes' root@koji.katello.org katello-mash-split.py"

            }
        }
        stage('Client Repoclosure') {
            steps {

                parallel(
                    'client/el7': { repoclosure('client', 'el7') },
                    'client/el6': { repoclosure('client', 'el6') },
                    'client/fc27': { repoclosure('client', 'f27') }
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
            agent { label 'el && ipv6' }

            environment {
                VAGRANT_DEFAULT_PROVIDER = 'openstack'
            }
            steps {

                git url: 'https://github.com/theforeman/forklift'

                sh "cp -f vagrant/boxes.d/99-local.yaml.example vagrant/boxes.d/99-local.yaml"
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
            agent { label 'admin && sshkey' }

            steps {

                sh "ssh -i /var/lib/workspace/workspace/deploy_katello_repos_key/deploy_katello_repos_key katelloproject@fedorapeople.org \"cd /project/katello/bin && sh rsync-repos-from-koji nightly\""

            }
        }
    }
}

void repoclosure(repo, dist, additions = []) {

    node('el') {
        git url: "https://github.com/theforeman/foreman-packaging", branch: "rpm/develop"

        def command = [
            "./repoclosure.sh yum_${dist}.conf",
            "http://koji.katello.org/releases/yum/katello-nightly/${repo}/${dist}/x86_64/",
            "-l ${dist}-foreman-nightly",
            "-l ${dist}-foreman-plugins-nightly",
            "-l ${dist}-foreman-rails-nightly",
            "-l ${dist}-base",
            "-l ${dist}-updates",
            "-l ${dist}-epel",
            "-l ${dist}-extras",
            "-l ${dist}-scl",
            "-l ${dist}-scl-sclo",
            "-l ${dist}-puppet-5",
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

