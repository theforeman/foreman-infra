pipeline {
    agent none

    options {
        timestamps()
            timeout(time: 2, unit: 'HOURS')
            disableConcurrentBuilds()
            ansiColor('xterm')
    }

    stages {
        stage('forklift centos7-devel pipeline tests') {
            agent { label 'el' }
            environment {
                cico_job_name = "foreman-forklift-centos-devel-test"
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
