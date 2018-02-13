def ruby = '2.4'
def katello_versions = [
    'master': 'develop',
    'KATELLO-3.6': '1.17-stable',
    'KATELLO-3.5': '1.16-stable'
]

pipeline {
    agent { label 'fast' }

    stages {
        stage('Setup Git Repos') {
            steps {
               checkout changelog: true, poll: false, scm: [
                   $class: 'GitSCM',
                   branches: [[name: '${ghprbActualCommit}']],
                   doGenerateSubmoduleConfigurations: false,
                   extensions: [[$class: 'PreBuildMerge', options: [fastForwardMode: 'FF', mergeRemote: 'origin', mergeStrategy: 'default', mergeTarget: '${ghprbTargetBranch}']]],
                   userRemoteConfigs: [
                       [refspec: '+refs/pull/${ghprbPullId}/*:refs/remotes/origin/pr/${ghprbPullId}/*', url: 'https://github.com/katello/katello']
                   ]
               ]

                dir('foreman') {
                    git url: "https://github.com/theforeman/foreman", branch: katello_versions[ghprbTargetBranch]
                }
            }
        }
        stage("Setup RVM") {
            steps {

                configureRVM(ruby)

            }
        }
        stage('Configure Environment') {
            steps {

                dir('foreman') {
                    addSettings([
                        organizations: true,
                        locations: true
                    ])
                    addGem()
                    databaseFile(gemset())
                }

            }
        }
        stage('Configure Database') {
            steps {

                dir('foreman') {
                    configureDatabase(ruby)
                }

            }
        }
        stage('Run Tests') {
            parallel {
                stage('tests') {
                    steps {
                        dir('foreman') {
                            withRVM(['bundle exec rake jenkins:katello TESTOPTS="-v" --trace'], ruby)
                        }
                    }
                }
                stage('rubocop') {
                    steps {
                        dir('foreman') {
                            withRVM(['bundle exec rake katello:rubocop TESTOPTS="-v" --trace'], ruby)
                        }
                    }
                }
                stage('react-ui') {
                    when {
                        expression { fileExists('package.json') }
                    }
                    steps {
                        sh 'npm install'
                        sh 'npm test'
                    }
                }
                stage('angular-ui') {
                    steps {
                        dir('foreman') {
                            withRVM(['bundle show bastion > bastion-version'], ruby)

                            script {
                                bastion_install = readFile('bastion-version')
                                bastion_version = bastion_install.split('bastion-')[1]
                                echo bastion_install
                                echo bastion_version
                            }
                        }

                        sh "cp -rf \$(cat foreman/bastion-version) engines/bastion_katello/bastion-${bastion_version}"

                        dir('engines/bastion_katello') {
                            sh "npm install npm"
                            sh "node_modules/.bin/npm install bastion-${bastion_version}"
                            sh "grunt ci"
                        }
                    }
                }
                stage('assets-precompile') {
                    steps {
                        dir('foreman') {
                            withRVM(['bundle exec rake plugin:assets:precompile[katello] RAILS_ENV=production --trace'], ruby)
                        }
                    }
                }
            }
        }
        stage('Test db:seed') {
            steps {

                dir('foreman') {

                    withRVM(['bundle exec rake db:drop'], ruby)
                    withRVM(['bundle exec rake db:create'], ruby)
                    withRVM(['bundle exec rake db:migrate'], ruby)
                    withRVM(['bundle exec rake db:seed'], ruby)

                }

            }
        }
    }

    post {
        always {
            dir('foreman') {
                archiveArtifacts artifacts: "Gemfile.lock"
                junit keepLongStdio: true, testResults: 'jenkins/reports/unit/*.xml'
                cleanup(ruby)
            }
            deleteDir()
        }
    }
}
