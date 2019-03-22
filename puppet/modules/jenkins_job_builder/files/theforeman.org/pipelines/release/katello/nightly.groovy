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
            parallel {

                stage('Install test') {
                    agent { label 'el' }
                    environment {
                        cico_job_name = "foreman-katello-nightly-test"
                    }

                    steps {
                        git_clone_foreman_infra()

                        withCredentials([string(credentialsId: 'centos-jenkins', variable: 'PASSWORD')]) {
                            runPlaybook(
                                playbook: 'ci/centos.org/ansible/jenkins_job.yml',
                                extraVars: [
                                    "jenkins_job_name": "${env.cico_job_name}",
                                    "jenkins_username": "foreman",
                                    "jenkins_job_link_file": "${env.WORKSPACE}/jobs/${env.cico_job_name}"
                                ],
                                sensitiveExtraVars: ["jenkins_password": "${env.PASSWORD}"]
                            )
                        }
                    }
                    post {
                        always {
                            script {
                                set_job_build_description("${env.cico_job_name}")
                            }
                        }
                    }
                }

                stage('Upgrade test') {
                    agent { label 'el' }
                    environment {
                        cico_job_name = "foreman-katello-upgrade-nightly-test"
                    }

                    steps {
                        git_clone_foreman_infra()
                        sleep(5) //See https://bugs.centos.org/view.php?id=14920

                        withCredentials([string(credentialsId: 'centos-jenkins', variable: 'PASSWORD')]) {
                            runPlaybook(
                                playbook: 'ci/centos.org/ansible/jenkins_job.yml',
                                extraVars: [
                                    "jenkins_job_name": "${env.cico_job_name}",
                                    "jenkins_username": "foreman",
                                    "jenkins_job_link_file": "${env.WORKSPACE}/jobs/${env.cico_job_name}"
                                ],
                                sensitiveExtraVars: ["jenkins_password": "${env.PASSWORD}"]
                            )
                        }
                    }
                    post {
                        always {
                            script {
                                set_job_build_description("${env.cico_job_name}")
                            }
                        }
                    }
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
            "-l ${dist}-puppet-5",
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
