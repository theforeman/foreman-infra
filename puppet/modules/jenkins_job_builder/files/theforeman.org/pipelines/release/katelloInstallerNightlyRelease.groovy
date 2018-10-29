pipeline {
    agent { label 'rpmbuild' }

    options {
        timestamps()
        timeout(time: 2, unit: 'HOURS')
        disableConcurrentBuilds()
        ansiColor('xterm')
    }

    environment {
        ruby_version = '2.4'
    }

    stages {
        stage('Setup Environment') {
            steps {
                dir('katello-installer') {
                    configureRVM(ruby_version)
                    git url: 'https://github.com/Katello/katello-installer', branch: 'master'
                    withRVM(['bundle install --without development --jobs=5 --retry 5'], ruby_version)

                    script {
                        if (fileExists('Puppetfile.lock')) {
                            sh 'rm Puppetfile.lock'
                        }
                    }
                }
                dir('foreman-packaging') {
                    git url: 'https://github.com/theforeman/foreman-packaging/', branch: 'rpm/develop'
                }
                setup_obal()
            }
        }

        stage('Build Tarball') {
            steps {
                dir('katello-installer') {
                    withRVM(['bundle exec rake pkg:generate_source'], ruby_version)
                    archiveArtifacts artifacts: 'pkg/*'
                }
            }
        }

        stage('Build RPM') {
            steps {
                dir('foreman-packaging') {
                    obal(
                        action: 'release',
                        packages: 'katello-installer-base',
                        extraVars: ['build_package_tito_releaser_args': ["--arg jenkins_job=${env.JOB_NAME} --arg jenkins_job_id=${env.BUILD_ID}"]]
                    )
                }
            }
        }
    }
}
