pipeline {
    agent any

    options {
        timestamps()
        timeout(time: 2, unit: 'HOURS')
        ansiColor('xterm')
        buildDiscarder(logRotator(daysToKeepStr: '7'))
    }

    stages {
        stage("Collect Git Hash") {
            steps {
                git(url: git_url, branch: git_ref)
                script {
                    archive_git_hash()
                }
                add_hammer_cli_git_repos(hammer_cli_git_repos)
            }
        }
        stage("test-ruby-2.5") {
            steps {
                run_test(ruby: '2.5')
            }
        }
        stage("test-ruby-2.6") {
            steps {
                run_test(ruby: '2.6')
            }
        }
        stage("test-ruby-2.7") {
            steps {
                run_test(ruby: '2.7')
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

def add_hammer_cli_git_repos(repos = []) {
    content = ''
    for(i = 0; i < repos.size(); i++) {
      content += "gem '${repos[i].replace('-', '_')}', :github => 'theforeman/${repos[i]}'\n"
    }
    writeFile(file: 'Gemfile.local', text: content)
}

def run_test(args) {
    def ruby = args.ruby
    def gemset = "ruby-${ruby}"

    try {
        configureRVM(ruby, gemset)
        withRVM(['bundle install --without=development --jobs=5 --retry=5'], ruby, gemset)
        withRVM(['bundle show'], ruby, gemset)
        withRVM(['bundle exec rake ci:setup:minitest test TESTOPTS="-v"'], ruby, gemset)
    } finally {
        cleanupRVM(ruby, gemset)
        junit(testResults: 'test/reports/*.xml')
    }
}
