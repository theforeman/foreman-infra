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
                mash('foreman-mash-split.py')
            }
        }
        stage('Repoclosure') {
            agent { label 'el' }

            steps {

                repoclosure('RHEL', '7')

            }
        }
        stage('Install Test') {
            steps {
                runCicoJob("foreman-nightly-centos7-test")
            }
        }
        stage('Push RPMs') {
            agent { label 'admin && sshkey' }

            steps {
                git_clone_foreman_infra()

                dir('deploy') {

                    withRVM(["bundle install --jobs=5 --retry=5"])
                    push_rpms_direct("foreman-nightly/RHEL/7", "nightly/el7")
                }
            }
            post {
                always {
                    deleteDir()
                }
            }
        }
    }
    post {
        failure {
            emailext(
                subject: "${env.JOB_NAME} ${env.BUILD_ID} failed",
                to: 'ci@community.theforeman.org',
                body: "Foreman RPM nightly pipeline failed: \n\n${env.BUILD_URL}"
            )
        }
    }
}

void repoclosure(repo, dist, additions = []) {

    node('el') {
        git url: "https://github.com/theforeman/foreman-packaging", branch: "rpm/develop", poll: false

        def command = [
            "./repoclosure.sh yum_el${dist}.conf",
            "http://koji.katello.org/releases/yum/foreman-nightly/${repo}/${dist}/x86_64/",
            "-l el${dist}-foreman-rails-nightly",
            "-l el${dist}-base",
            "-l el${dist}-updates",
            "-l el${dist}-epel",
            "-l el${dist}-extras",
            "-l el${dist}-scl",
            "-l el${dist}-puppet-5"
        ]

        command = command + additions

        dir('repoclosure') {
            sh command.join(" ")
        }

        deleteDir()
    }

}
