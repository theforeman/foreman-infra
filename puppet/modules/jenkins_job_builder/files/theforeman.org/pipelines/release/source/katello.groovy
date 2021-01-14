pipeline {
    options {
        timestamps()
        timeout(time: 3, unit: 'HOURS')
        ansiColor('xterm')
        buildDiscarder(logRotator(daysToKeepStr: '7'))
    }

    agent { label 'fast' }

    stages {
        stage('Setup Git Repos') {
            steps {
                deleteDir()
                git url: git_url, branch: git_ref
                script {
                    archive_git_hash()
                }

                dir('foreman') {
                   git url: "https://github.com/theforeman/foreman", branch: 'develop', poll: false, changelog: false
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
        stage('Install Foreman npm packages') {
            steps {
                dir('foreman') {
                    withRVM(["bundle exec npm install"], ruby)
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
                        sh "npm install"
                        sh 'npm test'
                    }
                }
                stage('angular-ui') {
                    steps {
                        script {
                            dir('engines/bastion') {
                                sh "npm install"
                                sh "grunt ci"
                            }
                            dir('engines/bastion_katello') {
                                sh "npm install"
                                sh "grunt ci"
                            }
                        }
                    }
                }
                stage('assets-precompile') {
                    steps {
                        dir('foreman') {
                            withRVM(["bundle exec rake plugin:assets:precompile[${project_name}] RAILS_ENV=production --trace"], ruby)
                        }
                    }
                }
            }
            post {
                always {
                    dir('foreman') {
                        archiveArtifacts artifacts: "log/test.log"
                        junit keepLongStdio: true, testResults: 'jenkins/reports/unit/*.xml'
                    }
                }
            }
        }
        stage('Test db:seed') {
            steps {

                dir('foreman') {

                    withRVM(['bundle exec rake db:drop RAILS_ENV=test || true'], ruby)
                    withRVM(['bundle exec rake db:create RAILS_ENV=test'], ruby)
                    withRVM(['bundle exec rake db:migrate RAILS_ENV=test'], ruby)
                    withRVM(['bundle exec rake db:seed RAILS_ENV=test'], ruby)

                }

            }
        }
        stage('Build and Archive Source') {
            steps {
                dir(project_name) {
                    git url: git_url, branch: git_ref
                }
                script {
                    generate_sourcefiles(project_name: project_name, source_type: source_type)
                }
            }
        }
    }

    post {
        success {
            build(
                job: "${project_name}-${git_ref}-package-release",
                propagate: false,
                wait: false
            )
        }

        failure {
            notifyDiscourse(env, "${project_name} source release pipeline failed:", currentBuild.description)
        }

        always {
            dir('foreman') {
                cleanup(ruby)
            }
            deleteDir()
        }
    }
}
