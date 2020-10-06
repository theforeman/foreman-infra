pipeline {
  agent { label 'admin && sshkey' }
  environment {
    ruby_version = '2.5'
  }
  triggers {
    cron('30 4 */7 * *')
  }
  stages {
    stage('Setup Environment') {
      steps {
        git url: 'https://github.com/theforeman/foreman', branch: 'develop'
        script {
          sh '(git show-branch i18n-updates &>/dev/null) && (git checkout i18n-updates) || (git checkout -b i18n-updates)'
          sh 'git rebase origin/develop'
          configureRVM(ruby_version)
          withRVM(['bundle install --jobs=5 --retry=5'], ruby_version)
          sh 'cp config/database.yml.example config/database.yml'
        }
      }
    }
    stage('Extract strings and update translations'){
      steps {
        script {
          configureRVM(ruby_version)
          withRVM([withCredentials([string(credentialsId: 'transifex-api-token', variable: 'TX_TOKEN')]) {
            'make -C locale/ tx-update'}], ruby_version)
          }
        }
      }
    stage('Test new strings'){
      steps {
        script {
          configureRVM(ruby_version)
          withRVM(['make -C locale/ all-mo'], ruby_version)
        }
      }
    }
    stage('Create PR with updated strings') {
      steps {
        script {
          sh "git commit --amend -m 'i18n - extracting new, pulling from tx(jenkins-auto-update)'"
          sh 'git push origin i18n-updates -f'
        }
      }
    }
  }
}