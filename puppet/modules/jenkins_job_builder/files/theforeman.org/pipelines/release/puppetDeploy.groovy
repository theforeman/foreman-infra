pipeline {
    agent { label 'admin && sshkey' }

    options {
        ansiColor('xterm')
        buildDiscarder(logRotator(numToKeepStr: '3'))
        disableConcurrentBuilds()
        timestamps()
    }

    stages {
        stage('Execute shell') {
            steps {
                git url: 'https://github.com/theforeman/foreman-infra.git'
                sh 'ssh -p 8122 deploypuppet@puppetmaster.theforeman.org -i /var/lib/workspace/workspace/deploy_key/deploy_key'
            }
        }
    }
}
