pipeline {
    options {
        timestamps()
        timeout(time: 2, unit: 'HOURS')
        ansiColor('xterm')
    }

    agent none

    stages {
        stage('Test') {
            matrix {
                agent { label 'fast' }
                axes {
                    axis {
                        name 'ruby'
                        values '2.5', '2.6', '2.7'
                    }
                }
                stages {
                    stage('Configure Environment') {
                        steps {
                            configureRVM(ruby)
                            deleteDir()
                            checkout scm: [
                                    $class: 'GitSCM',
                                    branches: [[name: params.plugin_branch]],
                                    userRemoteConfigs: [[url: params.plugin_repo]],
                                    extensions: [[$class: 'CloneOption', shallow: true, noTags: true]]
                                ],
                                poll: false

                            dir('foreman') {
                                checkout scm: [
                                        $class: 'GitSCM',
                                        branches: [[name: params.foreman_branch]],
                                        userRemoteConfigs: [[url: params.foreman_repo]],
                                        extensions: [[$class: 'CloneOption', shallow: true, noTags: true]]
                                    ],
                                    poll: false

                                addGem()
                                databaseFile(gemset())
                                configureDatabase(ruby)
                            }
                        }
                    }
                    stage('Unit Tests') {
                        steps {
                            dir('foreman') {
                                withRVM(['bundle exec rake jenkins:unit TESTOPTS="-v" --trace'], ruby)
                            }
                        }
                    }
                    stage('Acceptance Tests') {
                        when {
                            allOf {
                                expression { fileExists('test/integration') }
                                equals expected: '2.7', actual: ruby
                            }
                        }
                        steps {
                            dir('foreman') {
                                withRVM(
                                    [
                                        'bundle exec npm install',
                                        'bundle exec rake webpack:compile jenkins:integration TESTOPTS="-v" --trace'
                                    ],
                                    ruby
                                )
                            }
                        }
                    }
                    stage('Javascript') {
                        when {
                            expression { fileExists('package.json') }
                        }
                        steps {
                            sh "npm install"
                            sh 'npm test'
                        }
                    }
                    //stage('assets-precompile') {
                    //    steps {
                    //        dir('foreman') {
                    //            withRVM(
                    //                [
                    //                    'bundle exec npm install',
                    //                    "bundle exec rake plugin:assets:precompile[${plugin}] RAILS_ENV=production --trace"
                    //                ],
                    //                ruby
                    //            )
                    //        }
                    //    }
                    //}
                    stage('Test db:seed') {
                        steps {
                            dir('foreman') {
                                withRVM(
                                    [
                                        'bundle exec rake db:drop RAILS_ENV=test || true',
                                        'bundle exec rake db:create RAILS_ENV=test',
                                        'bundle exec rake db:migrate RAILS_ENV=test',
                                        'bundle exec rake db:seed RAILS_ENV=test'
                                    ],
                                    ruby
                                )
                            }
                        }
                    }
                }
                post {
                    always {
                        dir('foreman') {
                            archiveArtifacts artifacts: "log/test.log"
                            junit keepLongStdio: true, testResults: 'jenkins/reports/unit/*.xml'
                            cleanup(ruby)
                        }
                        deleteDir()
                        // ircNotify TODO
                    }
                }
            }
        }
    }
}
