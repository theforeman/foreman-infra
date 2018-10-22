pipeline {
    agent { label 'admin' }

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
            }
        }

        stage('Build Tarball') {
            steps {
                dir('katello-installer') {
                    withRVM(['bundle exec rake pkg:generate_source'], 'ruby_version)
                    archiveArtifacts artifacts: 'pkg/*'
                }
            }
        }

        stage('Trigger RPM Build') {
            steps {
                build job: 'packaging_build_rpm', propagate: true, parameters: [
                    string(name: 'project', value: 'packages/katello/katello-installer-base'),
                    booleanParam(name: 'gitrelease', value: false),
                    booleanParam(name: 'scratch', value: false),
                    string(name: 'releaser', value: 'koji-katello-jenkins'),
                    string(name: 'nightly_jenkins_job', value: env.getProperty('JOB_NAME')),
                    string(name: 'nightly_jenkins_job_id', value: env.getProperty('BUILD_ID'))
                ]
            }
        }
    }
}
