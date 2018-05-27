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

                sh "ssh -o 'BatchMode yes' root@koji.katello.org foreman-mash-split.py"

            }
        }
        stage('Repoclosure') {
            steps {

                repoclosure('RHEL', '7')

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
                sh "vagrant up centos7-foreman-bats-ci"

            }
            post {
                always {
                    sh "mkdir debug"
                    sh "vagrant ssh-config centos7-foreman-bats-ci > ssh_config"

                    sh "scp -F ssh_config centos7-foreman-bats-ci:/root/bats_results/*.tap debug/ || true"
                    sh "scp -F ssh_config centos7-foreman-bats-ci:/root/last_logs debug/ || true"
                    sh "scp -F ssh_config centos7-foreman-bats-ci:/root/sosreport* debug/ || true"
                    sh "scp -F ssh_config centos7-foreman-bats-ci:/root/foreman-debug.tar.xz debug/ || true"
                    sh "scp -F ssh_config centos7-foreman-bats-ci:/var/log/foreman-installer/foreman.log debug/ || true"

                    sh "vagrant destroy centos7-foreman-bats-ci"

                    archive "debug/*"
                    deleteDir()
                }
            }
        }
        stage('Push RPMs') {
            agent { label 'admin && sshkey' }

            steps {

                git url: 'https://github.com/theforeman/foreman-infra'

                dir('deploy') {

                    withRVM(["bundle install --jobs=5 --retry=5"])
                    withRVM(["cap yum repo:sync -S overwrite=true -S merge=false -S repo_source=foreman-nightly/RHEL/7 -S repo_dest=nightly/el7"])
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

void repoclosure(repo, dist, additions = []) {

    node('el') {
        git url: "https://github.com/theforeman/foreman-packaging", branch: "rpm/develop"

        def command = [
            "./repoclosure.sh yum_el${dist}.conf",
            "http://koji.katello.org/releases/yum/foreman-nightly/${repo}/${dist}/x86_64/",
            "-l el${dist}-base",
            "-l el${dist}-updates",
            "-l el${dist}-epel",
            "-l el${dist}-extras",
            "-l el${dist}-scl",
            "-l el${dist}-scl-sclo",
            "-l el${dist}-scl-ruby",
            "-l el${dist}-scl-v8",
            "-l el${dist}-puppet-4",
            "-l el${dist}-subscription-manager",
            "-l el${dist}-qpid",
            "-l el${dist}-tfm-ror51"
        ]

        command = command + additions

        dir('repoclosure') {
            sh command.join(" ")
        }

        deleteDir()
    }

}
