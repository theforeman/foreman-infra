def commit_hash = ''
foreman_branch = 'develop'

pipeline {
    agent { label 'fast' }

    options {
        timestamps()
        timeout(time: 2, unit: 'HOURS')
        ansiColor('xterm')
    }

    stages {
        stage('Test Matrix') {
            parallel {
                stage('ruby-2.5-postgres') {
                    agent { label 'fast' }
                    environment {
                        RUBY = '2.5'
                        GEMSET = 'ruby-2.5-postgres'
                    }
                    stages {
                        stage("setup-2.5-postgres") {
                            steps {
                                git url: 'https://github.com/theforeman/foreman', branch: foreman_branch
                                script {
                                    commit_hash = archive_git_hash()
                                }
                                configureRVM(env.RUBY, env.GEMSET)
                                databaseFile(gemset(env.GEMSET))
                                configureDatabase(env.RUBY, env.GEMSET)
                                withRVM(['npm install'], env.RUBY, env.GEMSET)
                            }
                        }
                        stage("unit-tests-2.5-postgres") {
                            steps {
                                withRVM(['bundle exec rake jenkins:unit TESTOPTS="-v" --trace'], env.RUBY, env.GEMSET)
                            }
                        }
                        stage("integration-tests-2.5-postgres") {
                            steps {
                                withRVM(['bundle exec rake jenkins:integration TESTOPTS="-v" --trace'], env.RUBY, env.GEMSET)
                            }
                        }
                        stage("assets-precompile-2.5-postgres") {
                            steps {
                                withRVM(['bundle exec rake assets:precompile RAILS_ENV=production'], env.RUBY, env.GEMSET)
                            }
                        }
                    }
                    post {
                        always {
                            cleanup(env.RUBY, env.GEMSET)
                            deleteDir()
                        }
                    }
                }
                stage('ruby-2.4-postgres') {
                    agent { label 'fast' }
                    environment {
                        RUBY = '2.4'
                        GEMSET = 'ruby-2.4-postgres'
                    }
                    stages {
                        stage("setup-2.4-postgres") {
                            steps {
                                git url: 'https://github.com/theforeman/foreman', branch: foreman_branch
                                configureRVM(env.RUBY, env.GEMSET)
                                databaseFile(gemset(env.GEMSET))
                                configureDatabase(env.RUBY, env.GEMSET)
                            }
                        }
                        stage("unit-tests-2.4-postgres") {
                            steps {
                                withRVM(['bundle exec rake jenkins:unit TESTOPTS="-v" --trace'], env.RUBY, env.GEMSET)
                            }
                        }
                    }
                    post {
                        always {
                            cleanup(env.RUBY, env.GEMSET)
                            deleteDir()
                        }
                    }
                }
                stage('ruby-2.3-postgres') {
                    agent { label 'fast' }
                    environment {
                        RUBY = '2.3'
                        GEMSET = 'ruby-2.3-postgres'
                    }
                    stages {
                        stage("setup-2.3-postgres") {
                            steps {
                                git url: 'https://github.com/theforeman/foreman', branch: foreman_branch
                                configureRVM(env.RUBY, env.GEMSET)
                                databaseFile(gemset(env.GEMSET))
                                configureDatabase(env.RUBY, env.GEMSET)
                            }
                        }
                        stage("unit-tests-2.3-postgres") {
                            steps {
                                withRVM(['bundle exec rake jenkins:unit TESTOPTS="-v" --trace'], env.RUBY, env.GEMSET)
                            }
                        }
                    }
                    post {
                        always {
                            cleanup(env.RUBY, env.GEMSET)
                            deleteDir()
                        }
                    }
                }
                stage('ruby-2.5-mysql') {
                    agent { label 'fast' }
                    environment {
                        RUBY = '2.5'
                        GEMSET = 'ruby-2.5-mysql'
                    }
                    stages {
                        stage("setup-2.5-mysql") {
                            steps {
                                git url: 'https://github.com/theforeman/foreman', branch: foreman_branch
                                configureRVM(env.RUBY, env.GEMSET)
                                databaseFile(gemset(env.GEMSET), 'mysql')
                                configureDatabase(env.RUBY, env.GEMSET)
                            }
                        }
                        stage("unit-tests-2.5-mysql") {
                            steps {
                                withRVM(['bundle exec rake jenkins:unit TESTOPTS="-v" --trace'], env.RUBY, env.GEMSET)
                            }
                        }
                    }
                    post {
                        always {
                            cleanup(env.RUBY, env.GEMSET)
                            deleteDir()
                        }
                    }
                }
                stage('ruby-2.5-sqlite3') {
                    agent { label 'fast' }
                    environment {
                        RUBY = '2.5'
                        GEMSET = 'ruby-2.5-sqlite3'
                    }
                    stages {
                        stage("setup-2.5-sqlite3") {
                            steps {
                                git url: 'https://github.com/theforeman/foreman', branch: foreman_branch
                                configureRVM(env.RUBY, env.GEMSET)
                                databaseFile(gemset(env.GEMSET), 'sqlite3')
                                configureDatabase(env.RUBY, env.GEMSET)
                            }
                        }
                        stage("unit-tests-2.5-sqlite3") {
                            steps {
                                withRVM(['bundle exec rake jenkins:unit TESTOPTS="-v" --trace'], env.RUBY, env.GEMSET)
                            }
                        }
                    }
                    post {
                        always {
                            cleanup(env.RUBY, env.GEMSET)
                            deleteDir()
                        }
                    }
                }
            }
        }
        stage('packaging') {
            steps {
                build(
                    job: 'foreman-develop-release',
                    propagate: false,
                    wait: false,
                    parameters: [
                        string(name: 'git_ref', value: commit_hash)
                    ]
                )
            }
        }
    }

    post {
        always {
            deleteDir()
        }
    }
}
