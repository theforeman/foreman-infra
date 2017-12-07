def packages_to_build

pipeline {
    agent { label 'rpmbuild' }

    parameters {
        string(name: 'previousCommit', defaultValue: 'HEAD', description: 'Previous commit in master')
    }

    triggers {
        pollSCM('* * * * *')
    }

    options {
        timestamps()
        timeout(time: 2, unit: 'HOURS')
        ansiColor('xterm')
        buildDiscarder(logRotator(numToKeepStr: '15'))
        disableConcurrentBuilds()
    }

    stages {
        stage('Clone Packaging') {
            steps {

                deleteDir()
                git url: 'https://github.com/theforeman/tfm-ror51-packaging', branch: 'master'

            }
        }
        stage('Release Build Packages') {
            steps {

                script {
                    runPlaybook {
                        inventory = 'package_manifest.yaml'
                        playbook = 'release_package.yml'
                        limit = packages_to_build
                    }
                }

            }
        }
    }
}
