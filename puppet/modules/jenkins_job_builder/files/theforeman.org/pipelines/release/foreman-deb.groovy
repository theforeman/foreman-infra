pipeline {
    agent none

    options {
        timestamps()
        timeout(time: 2, unit: 'HOURS')
        disableConcurrentBuilds()
        ansiColor('xterm')
    }

    stages {
        stage('Install tests') {
            parallel {

                stage('debian9') {
                    agent { label 'el' }
                    environment {
                        cico_job_name = "foreman-nightly-debian9-test"
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

                stage('ubuntu1604') {
                    agent { label 'el' }
                    environment {
                        cico_job_name = "foreman-nightly-ubuntu1604-test"
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

                stage('ubuntu1804') {
                    agent { label 'el' }
                    environment {
                        cico_job_name = "foreman-nightly-ubuntu1804-test"
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

            }
        }
        stage('Push DEBs') {
            agent { label 'admin && sshkey' }

            steps {
                push_debs_direct("debian9", "nightly")
                push_debs_direct("ubuntu1604", "nightly")
                push_debs_direct("ubuntu1804", "nightly")
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
                body: "Foreman DEB nightly pipeline failed: \n\n${env.BUILD_URL}"
            )
        }
    }
}
