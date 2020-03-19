def ruby = '2.5'

pipeline {

  options {
    ansiColor('xterm')
    disableConcurrentBuilds()
    timestamps()
  }

  stages {

    stage('Setup hammer plugin Git Repos') {
      steps {
        deleteDir()
        ghprb_git_checkout()
        dir('foreman') {
          git url: env.hammer_plugin_url, branch: env.hammer_plugin_branch, poll: false
        }

      }
    }

    stage('Setup RVM') {
      steps {
        configureRVM(ruby)
      }
    }

    stage('Run Tests') {
      steps {
        try {
            configureRVM(ruby_version)
            withRVM(["bundle install --jobs 5 --retry 5"], ruby)
            withRVM(["bundle exec rake ci:setup:minitest test TESTOPTS='-v'"], ruby)
        } finally {

           archive "Gemfile.lock"
           cleanupRVM(ruby)

        }
      }
    }
  }
}