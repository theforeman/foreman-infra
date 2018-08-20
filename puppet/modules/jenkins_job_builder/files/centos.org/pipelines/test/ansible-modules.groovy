pipeline {
    agent { label 'foreman' }

    stages {
        stage('Setup Environment') {
            steps {
                deleteDir()
                git url: 'https://github.com/theforeman/forklift.git'
            }
        }
        stage('Provision Node') {
            steps {

                provision()

            }
        }
        stage('Setup Openshift') {
            steps {

                containerPlaybook('tools/install-minishift.yml')
                containerPlaybook('tools/minishift-start.yml')

            }
        }
        stage('Copy Forklift') {
            steps {

                containerPlaybook('tools/install-forklift.yml')

            }
        }
        stage('Deploy to Openshift') {
            steps {

                containerPlaybook('tools/deploy.yml')

            }
        }
        stage('Clone foreman-ansible-modules') {
            steps {
                deleteDir()

                checkout changelog: true, poll: false, scm: [
                    $class: 'GitSCM',
                    branches: [[name: '${ghprbActualCommit}']],
                    doGenerateSubmoduleConfigurations: false,
                    extensions: [[$class: 'PreBuildMerge', options: [fastForwardMode: 'FF', mergeRemote: 'origin', mergeTarget: '${ghprbTargetBranch}']]],
                    userRemoteConfigs: [
                        [refspec: '+refs/pull/${ghprbPullId}/*:refs/remotes/origin/pr/${ghprbPullId}/*', url: 'https://github.com/theforeman/foreman-ansible-modules']
                    ]
                ]
            
            }
        }
        stage('Smoke Tests') {
            steps {
                route = getOcRoute('foreman-https')
                ansibleModulesPlaybook('test/test_playbooks/location.yml', route)
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
