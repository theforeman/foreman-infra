def packages_to_build

pipeline {
    agent { label 'rpmbuild' }

    options {
        timestamps()
        timeout(time: 2, unit: 'HOURS')
        ansiColor('xterm')
        buildDiscarder(logRotator(numToKeepStr: '15'))
    }

    stages {
        stage('Clone Packaging') {
            steps {

                deleteDir()
                checkout changelog: true, poll: false, scm: [
                    $class: 'GitSCM',
                    branches: [[name: '${ghprbActualCommit}']],
                    doGenerateSubmoduleConfigurations: false,
                    extensions: [[$class: 'PreBuildMerge', options: [fastForwardMode: 'FF', mergeRemote: 'origin', mergeStrategy: 'default', mergeTarget: 'master']]],
                    submoduleCfg: [],
                    userRemoteConfigs: [
                        [refspec: '+refs/pull/${ghprbPullId}/*:refs/remotes/origin/pr/${ghprbPullId}/*', url: 'https://github.com/theforeman/tfm-ror51-packaging']
                    ]
                ]

            }
        }
        stage('Find Packages to Build') {
            steps {

                script {
                    changed_packages = sh(returnStdout: true, script: "git diff origin/master --name-only -- 'packages/*.spec' | cut -d'/' -f2 |sort -u").trim()
                    packages_to_build = changed_packages.split().join(':')
                    update_build_description_from_packages(packages_to_build)
                }

            }
        }
        stage('Scratch Build Packages') {
            steps {

                script {
                    runPlaybook {
                        inventory = 'package_manifest.yaml'
                        playbook = 'scratch_build.yml'
                        limit = packages_to_build
                    }
                }

            }
        }
        stage('Check Repoclosure') {
            steps {

                script {
                    runPlaybook {
                        inventory = 'package_manifest.yaml'
                        playbook = 'repoclosure.yml'
                    }
                }

            }
        }
    }
}

def update_build_description_from_packages(packages_to_build) {
    build_description = "${packages_to_build}"
    currentBuild.description = build_description
}
