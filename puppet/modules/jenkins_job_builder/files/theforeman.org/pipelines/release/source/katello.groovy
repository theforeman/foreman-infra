def commit_hash = ''
foreman_branch = 'master'
project_name = 'katello'
source_type = 'gem'
ruby = '2.5'

pipeline {
    options {
        timestamps()
        timeout(time: 2, unit: 'HOURS')
        ansiColor('xterm')
    }

    agent { label 'fast' }

    stages {
        stage('Setup Git Repos') {
            steps {
                deleteDir()
                git url: "https://github.com/Katello/${project_name}", branch: foreman_branch
                script {
                    commit_hash = archive_git_hash()
                }

                dir('foreman') {
                   git url: "https://github.com/theforeman/foreman", branch: 'develop', poll: false
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
                        sh 'npm run lint'
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
                            withRVM(["bundle exec npm install"], ruby)
                            withRVM(["bundle exec rake plugin:assets:precompile[${project_name}] RAILS_ENV=production --trace"], ruby)
                        }
                    }
                }
            }
            post {
                always {
                    dir('foreman') {
                        archiveArtifacts artifacts: "Gemfile.lock, log/test.log"
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
                    git url: "https://github.com/katello/${project_name}", branch: foreman_branch
                }
                script {
                    sourcefile_paths = generate_sourcefiles(project_name: project_name, source_type: source_type)
                }
            }
        }
        stage('Build Packages') {
            steps {
                build(
                    job: "${project_name}-${foreman_branch}-package-release",
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
