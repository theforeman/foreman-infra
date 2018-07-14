def katello_versions = [
    'master': 'develop',
    'KATELLO-3.7': '1.18-stable',
    'KATELLO-3.6': '1.17-stable',
    'KATELLO-3.5': '1.16-stable'
]
def ruby = '2.4'

pipeline {
    agent { label 'fast' }

    stages {
        stage('Setup Git Repos') {
            steps {
                deleteDir()
                ghprb_git_checkout()

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
                    withRVM(['bundle install --jobs=5 --retry=5'], ruby)
                }

            }
        }
        stage('Run Tests') {
            parallel {
                stage('react-ui') {
                    steps {
                        sh "npm install npm"
                        sh "node_modules/.bin/npm install"
                        sh 'npm test'
                    }
                }
                stage('assets-precompile') {
                    steps {
                        dir('foreman') {
                            sh "npm install npm"
                            withRVM(["bundle exec node_modules/.bin/npm install"], ruby)
                            withRVM(['DATABASE_URL=sqlite3::memory: bundle exec rake plugin:assets:precompile[katello] RAILS_ENV=production --trace'], ruby)
                        }
                    }
                }
            }
        }
    }

    post {
        always {
            dir('foreman') {
                cleanupRVM('', ruby)
            }
            deleteDir()
        }
    }
}
