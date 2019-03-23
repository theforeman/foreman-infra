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
                git url: 'https://github.com/theforeman/rails-packaging', branch: 'tfm-ror51', poll: false

            }
        }
        stage('Release Build Packages') {
            steps {

                obal(
                    action: 'release',
                    packages: 'all'
                )

            }
        }
    }
}
