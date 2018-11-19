pipeline {
    agent { label 'el' }

    options {
        timestamps()
        timeout(time: 2, unit: 'HOURS')
        disableConcurrentBuilds()
        ansiColor('xterm')
    }

    stages {
        stage('Run simple ci.centos.org test') {
            steps {
                deleteDir()
                git_clone_foreman_infra()

                withCredentials([string(credentialsId: 'centos-jenkins', variable: 'PASSWORD')]) {
                    runPlaybook(
                        playbook: 'ci/centos.org/ansible/jenkins_job.yml',
                        extraVars: [
                            "jenkins_job_name=foreman-ci-centos-simple-test",
                            "jenkins_username=foreman",
                            "jenkins_password=${env.PASSWORD}",
                            "jenkins_job_link_file=${env.WORKSPACE}/jobs/foreman-ci-centos-simple-test"
                        ],
                        options: ['-b']
                    )
                }

                withCredentials([string(credentialsId: 'centos-jenkins', variable: 'PASSWORD')]) {
                    runPlaybook(
                        playbook: 'ci/centos.org/ansible/jenkins_job.yml',
                        extraVars: [
                            "jenkins_job_name=foreman-ci-centos-simple-test",
                            "jenkins_username=foreman",
                            "jenkins_password=${env.PASSWORD}",
                            "jenkins_job_link_file=${env.WORKSPACE}/jobs/foreman-ci-centos-simple-test-2"
                        ],
                        options: ['-b']
                    )
                }
            }
        }
    }
    post {
        always {
            script {
                set_job_build_description()
            }
        }
    }
}
