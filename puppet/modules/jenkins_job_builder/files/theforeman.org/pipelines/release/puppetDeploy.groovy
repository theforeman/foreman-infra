pipeline {
    agent { label 'admin && sshkey' }

    options {
        ansiColor('xterm')
        buildDiscarder(logRotator(numToKeepStr: '3'))
        disableConcurrentBuilds()
        timestamps()
    }

    triggers {
        pollSCM('H/5 * * * *')
    }

    stages {
        stage('Execute shell') {
            steps {
                sh 'ssh -p 8122 deploypuppet@puppetmaster.theforeman.org -i /var/lib/workspace/workspace/deploy_key/deploy_key'
            }
        }
    }
}
