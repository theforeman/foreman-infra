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

                mash("katello-mash-split-3.11.py")

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
        stage('Test Suites') {
            parallel {
                stage('Install test') {
                    agent { label 'el' }
                    environment {
                        cico_job_name = 'foreman-katello-3.11-test'
                    }

                    steps {

                        git_clone_foreman_infra()

                        withCredentials([string(credentialsId: 'centos-jenkins', variable: 'PASSWORD')]) {
                            runPlaybook(
                                playbook: 'ci/centos.org/ansible/jenkins_job.yml',
                                inventory: 'localhost',
                                extraVars: [
                                  "jenkins_job_name": "${env.cico_job_name}",
                                  "jenkins_username": "foreman"
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
                        cico_job_name = 'foreman-katello-upgrade-3.11-test'
                    }

                    steps {

                        git_clone_foreman_infra()
                        sleep(5) //See https://bugs.centos.org/view.php?id=14920

                        withCredentials([string(credentialsId: 'centos-jenkins', variable: 'PASSWORD')]) {
                            runPlaybook(
                                playbook: 'ci/centos.org/ansible/jenkins_job.yml',
                                extraVars: [
                                  "jenkins_job_name": "${env.cico_job_name}",
                                  "jenkins_username": "foreman"
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

                sh "ssh -i /var/lib/workspace/workspace/deploy_katello_repos_key/deploy_katello_repos_key katelloproject@fedorapeople.org \"cd /project/katello/bin && sh rsync-repos-from-koji 3.11\""

            }
        }
    }
}

void repoclosure(repo, dist, additions = []) {

    node('el') {
        git url: "https://github.com/theforeman/foreman-packaging", branch: "rpm/1.21", poll: false

        def command = [
            "./repoclosure.sh yum_${dist}.conf",
            "http://koji.katello.org/releases/yum/katello-3.11/${repo}/${dist}/x86_64/",
            "-l ${dist}-foreman-1.21",
            "-l ${dist}-foreman-plugins-1.21",
            "-l ${dist}-foreman-rails-1.21",
            "-l ${dist}-base",
            "-l ${dist}-updates",
            "-l ${dist}-epel",
            "-l ${dist}-extras",
            "-l ${dist}-scl",
            "-l ${dist}-puppet-5",
            "-l ${dist}-subscription-manager",
            "-l ${dist}-qpid",
            "-l ${dist}-katello-pulp-3.11",
            "-l ${dist}-katello-candlepin-3.11"
        ]

        command = command + additions

        dir('repoclosure') {
            sh command.join(" ")
        }

        deleteDir()
    }

}
