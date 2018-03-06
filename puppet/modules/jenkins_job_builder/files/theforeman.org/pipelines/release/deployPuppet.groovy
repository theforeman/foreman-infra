pipeline {
    agent { label 'admin && sshkey' }

    options {
        timestamps()
        disableConcurrentBuilds()
        ansiColor('xterm')
    }

    stages {
        stage('Execute shell') {
            steps {
                sh 'ssh -p 8122 deploypuppet@puppetmaster.theforeman.org -i /var/lib/workspace/workspace/deploy_key/deploy_key'
            }
        }
    }
}
