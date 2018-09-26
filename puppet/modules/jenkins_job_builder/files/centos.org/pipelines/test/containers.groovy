pipeline {
    agent { label 'foreman' }

    stages {
        stage('Setup Environment') {
            steps {
                deleteDir()

                checkout changelog: true, poll: false, scm: [
                    $class: 'GitSCM',
                    branches: [[name: '${ghprbActualCommit}']],
                    doGenerateSubmoduleConfigurations: false,
                    extensions: [[$class: 'PreBuildMerge', options: [fastForwardMode: 'FF', mergeRemote: 'origin', mergeTarget: '${ghprbTargetBranch}']]],
                    userRemoteConfigs: [
                        [refspec: '+refs/pull/${ghprbPullId}/*:refs/remotes/origin/pr/${ghprbPullId}/*', url: 'https://github.com/theforeman/forklift']
                    ]
                ]
            }
        }
        stage('Provision Node') {
            when {
                expression { folderChanged([/^containers\//]) }
            }
            steps {

                provision()

            }
        }
        stage('Setup Openshift') {
            when {
                expression { folderChanged([/^containers\//]) }
            }
            steps {

                containerPlaybook('tools/install-minishift.yml')
                containerPlaybook('tools/minishift-start.yml')

            }
        }
        stage('Copy Forklift') {
            when {
                expression { folderChanged([/^containers\//]) }
            }
            steps {

                containerPlaybook('tools/install-forklift.yml')

            }
        }
        stage('Deploy to Openshift') {
            when {
                expression { folderChanged([/^containers\//]) }
            }
            steps {

                containerPlaybook('tools/deploy.yml')

            }
        }
        stage('Smoke Tests') {
            when {
                expression { folderChanged([/^containers\//]) }
            }
            steps {

                containerPlaybook('tools/run-tests.yml')

            }
        }
    }

    post {
        always {

            deprovision()
            deleteDir()

        }
    }
}
