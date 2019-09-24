pipeline {
    agent { label 'foreman' }

    environment {
        proxy_repository = env.getProperty('proxy_repository')
        branch = env.getProperty('branch')
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
                )
            }
        }
        stage('Run Build') {
            steps {
                script {
                    duffy_ssh("git clone https://github.com/theforeman/foreman-discovery-image/ --branch ${env.branch}", 'duffy_box', './')
                    duffy_ssh("cd foreman-discovery-image/aux/vagrant-build/ && vagrant up el7", 'duffy_box', './')
                    duffy_ssh("cd foreman-discovery-image/aux/vagrant-build/ && vagrant ssh -c \"sudo chmod +rx /root\" el7", 'duffy_box', './')
                    duffy_ssh("cd foreman-discovery-image/aux/vagrant-build/ && vagrant scp el7:/root/foreman-discovery-image/ ./result", 'duffy_box', './')
                    duffy_scp('foreman-discovery-image/aux/vagrant-build/result/', '.', 'duffy_box', './')
                }
            }
        }
    }

    post {
        success {
            archiveArtifacts artifacts: 'result/*tar', allowEmptyArchive: true
            archiveArtifacts artifacts: 'result/*iso', allowEmptyArchive: true
        }

        cleanup {
            deprovision()
            deleteDir()
        }
    }
}
