pipeline {
    agent { label 'foreman' }

    stages {
        stage('Setup Environment') {
            steps {
                deleteDir()
                git url: 'https://github.com/theforeman/forklift.git'
            }
        }
        stage('Provision Node') {
            steps {
                dir('foreman-infra') {
                    git url: 'https://github.com/theforeman/foreman-infra.git'
                }
  
                provision()
            }
        }
        stage('Install Pipeline Requirements') {
            steps {
                runPlaybook('playbooks/setup_forklift.yml', cico_inventory('./'), [], ['-b'])
            }
        }
        stage('Run Pipeline') {
            steps {
                duffy_ssh("cd forklift && ansible-playbook pipelines/pipeline_katello_nightly.yml -e forklift_state=up", 'duffy_box', './')
            }
        }
    }

    post {
        always {
            script {
                duffy_ssh("cd forklift && ansible-playbook playbooks/collect_debug.yml -l pipeline-katello-nightly-centos7", 'duffy_box', './')
                runPlaybook('foreman-infra/ci/centos.org/ansible/fetch_debug_files.yml', cico_inventory('./'), ["workspace=/home/foreman/workspace/${env.JOB_NAME}/debug"], ['-b'])
            }

            archiveArtifacts artifacts: 'debug/**/*.tap'
            archiveArtifacts artifacts: 'debug/**/*.tar.xz'

            deprovision()
            deleteDir()
        }
    }
}
