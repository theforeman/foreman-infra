pipeline {
    agent { label 'foreman' }
    environment {
      playBook = playBookVars()
    }

    stages {
        stage('Setup Environment') {
            steps {
                deleteDir()
                git url: 'https://github.com/theforeman/forklift.git'
            }
        }
        stage('Provision Node') {
            steps {
                provision()
            }
        }
        stage('Install Pipeline Requirements') {
            steps {
                runPlaybook(
                    playbook: 'playbooks/setup_forklift.yml',
                    inventory: cico_inventory('./'),
                    options: ['-b']
                  )
            }
        }
        stage('Run Pipeline') {
            steps {
                script {
                    extra_vars = buildExtraVars(extraVars: playBook['extraVars'])
                    duffy_ssh("cd forklift && ansible-playbook pipelines/${playBook['pipeline']} -e forklift_state=up ${extra_vars}", 'duffy_box', './')
                }
            }
        }
    }

    post {
        always {
            script {
                duffy_ssh("cd forklift && ansible-playbook playbooks/collect_debug.yml -l ${playBook['boxes'].join(',')}", 'duffy_box', './')
                runPlaybook(
                    playbook: 'foreman-infra/ci/centos.org/ansible/fetch_debug_files.yml',
                    inventory: cico_inventory('./'),
                    extraVars: ["workspace": "${env.WORKSPACE}/debug"],
                    commandLineExtraVars: true,
                    options: ['-b']
                  )
            }

            archiveArtifacts artifacts: 'debug/**/*.tap', allowEmptyArchive: true
            archiveArtifacts artifacts: 'debug/**/*.tar.xz', allowEmptyArchive: true
            archiveArtifacts artifacts: 'debug/**/*.xml', allowEmptyArchive: true

            step([$class: "TapPublisher", testResults: "debug/**/*.tap"])
            junit testResults: "debug/**/*.xml", allowEmptyResults: true

            deprovision()
            deleteDir()
        }
    }
}
