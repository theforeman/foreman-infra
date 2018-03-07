pipeline {
    agent { label 'admin && sshkey' }
    options {
        timestamps()
        disableConcurrentBuilds()
        ansiColor('xterm')
    }
    stages {
        stage('Setup Environment') {
            steps {
                git url: 'https://github.com/theforeman/foreman-infra'
            }
        }
        stage('Deploy') {
            steps {
                sh 'ssh -p 8122 deploypuppet@puppetmaster.theforeman.org -i /var/lib/workspace/workspace/deploy_key/deploy_key'
            }
        }
    }
}
