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
            agent { label 'el' }

            steps {

                repoclosure('RHEL', '7')

            }
        }
        stage('Install Test') {
            agent { label 'el' }

            steps {

                git_clone_foreman_infra()

                withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'jenkins-centos', passwordVariable: 'PASSWORD', usernameVariable: 'USERNAME']]) {
                    runPlaybook(
                        playbook: 'ci/centos.org/ansible/jenkins_job.yml',
                        extraVars: [
                            "jenkins_job_name=foreman-nightly-test",
                            "jenkins_username=${env.USERNAME}",
                            "jenkins_password=${env.PASSWORD}",
                            "jenkins_job_link_file=${env.WORKSPACE}/jobs/foreman-nightly-test"
                        ],
                        options: ['-b']
                    )
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
        stage('Push RPMs') {
            agent { label 'admin && sshkey' }

            steps {
                git_clone_foreman_infra()

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
    post {
        failure {
            emailext(
                subject: "${env.JOB_NAME} ${env.BUILD_ID} failed",
                to: 'ci@community.theforeman.org',
                body: "Foreman nightly pipeline failed: \n\n${env.BUILD_URL}"
            )
        }
    }
}

void repoclosure(repo, dist, additions = []) {

    node('el') {
        git url: "https://github.com/theforeman/foreman-packaging", branch: "rpm/develop"

        def command = [
            "./repoclosure.sh yum_el${dist}.conf",
            "http://koji.katello.org/releases/yum/foreman-nightly/${repo}/${dist}/x86_64/",
            "-l el${dist}-foreman-rails-nightly",
            "-l el${dist}-base",
            "-l el${dist}-updates",
            "-l el${dist}-epel",
            "-l el${dist}-extras",
            "-l el${dist}-scl",
            "-l el${dist}-scl-sclo",
            "-l el${dist}-puppet-5"
        ]

        command = command + additions

        dir('repoclosure') {
            sh command.join(" ")
        }

        deleteDir()
    }

}
