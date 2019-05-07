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

                mash("katello-mash-split.py")

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
        stage('Install tests and Upgrade tests') {
            steps {
                script {
                    runCicoJobsInParallel([
                        ['name': 'Install test', 'job': 'foreman-katello-nightly-test'],
                        ['name': 'Upgrade test', 'job': 'foreman-katello-upgrade-nightly-test']
                    ])
                }
            }
        }
        stage('Push RPMs') {
            agent { label 'admin && sshkey' }

            steps {
                push_rpms_katello("nightly")
            }
        }
    }
    post {
        failure {
            emailext(
                subject: "${env.JOB_NAME} ${env.BUILD_ID} failed",
                to: 'ci@community.theforeman.org',
                body: "Katello nightly pipeline failed: \n\n${env.BUILD_URL}"
            )
        }
    }
}

void repoclosure(repo, dist, additions = []) {

    node('el') {
        git url: "https://github.com/theforeman/foreman-packaging", branch: "rpm/develop", poll: false

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
            "-l ${dist}-puppet-6",
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
