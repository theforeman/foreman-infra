pipeline {
    agent { label 'fast' }

    options {
        timestamps()
        timeout(time: 2, unit: 'HOURS')
        ansiColor('xterm')
        buildDiscarder(logRotator(daysToKeepStr: '7'))
    }

    stages {
        stage('Test Matrix') {
            parallel {
                stage('ruby-2.6-postgres') {
                    agent { label 'fast' }
                    environment {
                        RUBY_VER = '2.6'
                        GEMSET = 'ruby-2.6-postgres'
                    }
                    stages {
                        stage("setup-2.6-postgres") {
                            steps {
                                git url: git_url, branch: git_ref
                                script {
                                    archive_git_hash()
                                }
                                configureRVM(env.RUBY_VER, env.GEMSET)
                                databaseFile(gemset(env.GEMSET))
                                configureDatabase(env.RUBY_VER, env.GEMSET)
                            }
                        }
                        stage("unit-tests-2.6-postgres") {
                            steps {
                                withRVM(['bundle exec rake jenkins:unit TESTOPTS="-v" --trace'], env.RUBY_VER, env.GEMSET)
                            }
                        }
                    }
                    post {
                        always {
                            cleanup(env.RUBY_VER, env.GEMSET)
                            junit(testResults: 'jenkins/reports/unit/*.xml')
                            deleteDir()
                        }
                    }
                }
                stage('ruby-2.5-postgres') {
                    agent { label 'fast' }
                    environment {
                        RUBY_VER = '2.5'
                        GEMSET = 'ruby-2.5-postgres'
                    }
                    stages {
                        stage("setup-2.5-postgres") {
                            steps {
                                git url: git_url, branch: git_ref
                                configureRVM(env.RUBY_VER, env.GEMSET)
                                databaseFile(gemset(env.GEMSET))
                                configureDatabase(env.RUBY_VER, env.GEMSET)
                            }
                        }
                        stage("unit-tests-2.5-postgres") {
                            steps {
                                withRVM(['bundle exec rake jenkins:unit TESTOPTS="-v" --trace'], env.RUBY_VER, env.GEMSET)
                            }
                        }
                    }
                    post {
                        always {
                            cleanup(env.RUBY_VER, env.GEMSET)
                            junit(testResults: 'jenkins/reports/unit/*.xml')
                            deleteDir()
                        }
                    }
                }
                stage('ruby-2.5-postgres-integrations') {
                    agent { label 'fast' }
                    environment {
                        RUBY_VER = '2.5'
                        GEMSET = 'ruby-2.5-postgres-ui'
                    }
                    stages {
                        stage("setup-2.5-postgres-ui") {
                            steps {
                                git url: git_url, branch: git_ref
                                configureRVM(env.RUBY_VER, env.GEMSET)
                                databaseFile(gemset(env.GEMSET))
                                configureDatabase(env.RUBY_VER, env.GEMSET)
                                withRVM(['npm install'], env.RUBY_VER, env.GEMSET)
                            }
                        }
                        stage("integration-tests-2.5-postgres-ui") {
                            steps {
                                withRVM(['bundle exec rake jenkins:integration TESTOPTS="-v" --trace'], env.RUBY_VER, env.GEMSET)
                            }
                        }
                    }
                    post {
                        always {
                            cleanup(env.RUBY_VER, env.GEMSET)
                            junit(testResults: 'jenkins/reports/unit/*.xml')
                            deleteDir()
                        }
                    }
                }
                stage('ruby-2.5-nulldb-assets') {
                    agent { label 'fast' }
                    environment {
                        RUBY_VER = '2.5'
                        GEMSET = 'ruby-2.5-nulldb-assets'
                    }
                    stages {
                        stage("setup-2.5-nulldb") {
                            steps {
                                git url: git_url, branch: git_ref
                                configureRVM(env.RUBY_VER, env.GEMSET)
                                withRVM(['bundle install --without=development --jobs=5 --retry=5'], env.RUBY_VER, env.GEMSET)
                                sh "cp db/schema.rb.nulldb db/schema.rb"
                                withRVM(['npm install'], env.RUBY_VER, env.GEMSET)
                            }
                        }
                        stage("assets-precompile-2.5-nulldb") {
                            steps {
                                withRVM(['bundle exec rake assets:precompile RAILS_ENV=production DATABASE_URL=nulldb://nohost'], env.RUBY_VER, env.GEMSET)
                            }
                        }
                    }
                    post {
                        always {
                            cleanup(env.RUBY_VER, env.GEMSET)
                            deleteDir()
                        }
                    }
                }
                stage('ruby-2.5-sqlite3') {
                    agent { label 'fast' }
                    environment {
                        RUBY_VER = '2.5'
                        GEMSET = 'ruby-2.5-sqlite3'
                    }
                    stages {
                        stage("setup-2.5-sqlite3") {
                            steps {
                                git url: git_url, branch: git_ref
                                configureRVM(env.RUBY_VER, env.GEMSET)
                                databaseFile(gemset(env.GEMSET), 'sqlite3')
                                configureDatabase(env.RUBY_VER, env.GEMSET)
                            }
                        }
                        stage("unit-tests-2.5-sqlite3") {
                            steps {
                                withRVM(['bundle exec rake jenkins:unit TESTOPTS="-v" --trace'], env.RUBY_VER, env.GEMSET)
                            }
                        }
                    }
                    post {
                        always {
                            cleanup(env.RUBY_VER, env.GEMSET)
                            junit(testResults: 'jenkins/reports/unit/*.xml')
                            deleteDir()
                        }
                    }
                }
            }
        }
        stage('Build and Archive Source') {
            steps {
                dir(project_name) {
                    git url: git_url, branch: git_ref
                }
                script {
                    sourcefile_paths = generate_sourcefiles(project_name: project_name, source_type: source_type)
                }
            }
        }
        stage('Build Packages') {
            steps {
                build(
                    job: "${project_name}-${git_ref}-package-release",
                    propagate: false,
                    wait: false
                )
            }
        }
    }

    post {
        failure {
            notifyDiscourse(env, "${project_name} source release pipeline failed:", currentBuild.description)
        }
        always {
            deleteDir()
        }
    }
}
