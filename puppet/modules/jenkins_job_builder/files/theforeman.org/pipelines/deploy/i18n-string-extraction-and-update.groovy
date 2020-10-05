pipeline {
  agent { label 'admin && sshkey' }
  environment {
  ruby_version = '2.5'
  triggers {
  	 TZ='Asia/Kolkata'
  	 cron('0 10 */7 * *')
  }
  }
  stages {
    stage('Setup Environment') {
      steps {
        git url: 'https://github.com/theforeman/foreman', branch: 'develop'
        script {
          sh 'git checkout -b i18n-updates'
          configureRVM(ruby_version)
          withRVM(['bundle install --jobs=5 --retry=5'], ruby_version)
          sh 'cp config/database.yml.example config/database.yml'
        }
      }
    }
    stage('Extract strings and update translations'){
      steps {
        script {
          withCredentials([string(credentialsId: 'transifex-api-token', variable: 'TX_TOKEN')]) {
            sh 'make -C locale/ tx-update'
          }
        }
      }
    }
    stage('Test new strings'){
      steps {
        script {
          sh 'make -C locale/ all-mo'
        }
      }
    }
    stage('Create PR with updated strings') {
      steps {
        script {
          sh 'git commit --amend i18n - extracting new, pulling from tx(jenkins-auto-update)'
          sh 'git branch -D i18n-updates'
        }
      }
    }
  }
}

def gemset(name = null) {

    def base_name = env.BUILD_TAG

    if (EXECUTOR_NUMBER != '0') {
        base_name += '-' + EXECUTOR_NUMBER
    }

    if (name) {
        base_name += '-' + name.replace(".", "-")
    }

    base_name
}

def configureRVM(ruby = '2.0', name = '') {
    emptyGemset(ruby, name)
    withRVM(["gem install bundler -v '< 2.0'"], ruby, name)
}

def emptyGemset(ruby = '2.0', name = '') {
    withRVM(["rvm gemset empty ${gemset(name)} --force"], ruby, name)
}

def cleanupRVM(ruby = '2.0', name = '') {
    withRVM(["rvm gemset delete ${gemset(name)} --force"], ruby, name)
}

def withRVM(commands, ruby = '2.0', name = '') {

    commands = commands.join("\n")
    echo commands.toString()

    sh """#!/bin/bash -l
        set +e
        rvm use ruby-${ruby}@${gemset(name)} --create
        ${commands}
    """
}
