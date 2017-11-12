pipeline {
    agent { label 'rpmbuild' }

    options {
        timestamps()
        timeout(time: 2, unit: 'HOURS')
        ansiColor('xterm')
        buildDiscarder(logRotator(numToKeepStr: '15'))
    }

    triggers {
        cron('0 0 * * *')
    }

    stages {
        stage('Clone Packaging') {
            steps {

                deleteDir()
                git url: 'https://github.com/theforeman/tfm-ror51-packaging', branch: 'master'

            }
        }
        stage('Find and Remove Copr Scratch Repositories') {
            steps {

                script {

                    runPlaybook {
                        inventory = 'package_manifest.yaml'
                        playbook = 'cleanup_copr.yml'
                        limit = packages_to_build
                    }

                }

            }
        }
    }
}
