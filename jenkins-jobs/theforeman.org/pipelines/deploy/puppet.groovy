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
                git_clone_foreman_infra()
                sshagent(['puppet-deploy']) {
                    sh 'ssh -p 8122 deploypuppet@puppetmaster.theforeman.org'
                }
            }
        }
    }
}
