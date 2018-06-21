pipeline {
    agent { label 'rpmbuild' }

    options {
        timestamps()
        timeout(time: 2, unit: 'HOURS')
        disableConcurrentBuilds()
        ansiColor('xterm')
    }

    stages {
        stage ("Build Gem") {
            steps {
                dir('gem-build') {
                    git(url: "https://github.com/${owner_repo}", branch: branch)
                    sh("gem build ${gemspec}")
                    archiveArtifacts(artifacts: '*.gem')
                }
            }
        }

        stage('Build RPM') {
            steps {
                dir('foreman-packaging') {
                    git(url: 'https://github.com/theforeman/foreman-packaging', branch: 'rpm/develop')
                    obal(action: "release", extraVars: ['build_package_tito_releaser_args': ["--arg jenkins_job=${env.JOB_NAME}", "--arg jenkins_job_id=${env.BUILD_ID}"]], packages: package_name)
                }
            }
        }
    }
}
