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
        stage('Find Packages to Build') {
            steps {

                script {
                    merge_info = sh(returnStdout: true, script: "git rev-list --parents -n 1 ${previousCommit}").split()
                    packages_to_build = sh(returnStdout: true, script: "git diff ${merge_info[1]}...${merge_info[0]} --name-only -- 'packages/*.spec' | cut -d'/' -f2 |sort -u").trim()
                    packages_to_build = packages_to_build.split().join(':')
                }

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
