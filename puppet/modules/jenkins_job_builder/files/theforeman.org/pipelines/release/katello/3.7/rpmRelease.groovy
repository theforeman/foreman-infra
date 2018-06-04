def foreman_version = '1.18'
def ruby = '2.4'

pipeline {
    agent { label 'admin' }

    options {
        timestamps()
        timeout(time: 2, unit: 'HOURS')
        disableConcurrentBuilds()
        ansiColor('xterm')
    }

    stages {
        stage('Build Source') {
            parallel {
                stage('build-katello-installer-tarball') {
                    steps {
                        dir('katello-installer') {
                            configureRVM(ruby)
                            git url: 'https://github.com/Katello/katello-installer', branch: versions[foreman_version]['katello']
                            withRVM(['bundle install --without development --jobs=5 --retry 5'], ruby)
                            withRVM(['bundle exec rake pkg:generate_source'], ruby)
                            archiveArtifacts artifacts: 'pkg/*'
                        }
                    }
                }
                stage('build-rubygem-katello-gem') {
                    steps {
                        dir('katello') {
                            git url: 'https://github.com/Katello/katello', branch: versions[foreman_version]['katello']
                            sh "gem build katello.gemspec"
                            archiveArtifacts artifacts: "*.gem"
                        }
                    }
                }
            }
        }

        stage('Build RPMs') {
            parallel {
                stage('build-katello-installer-rpm') {
                    steps {
                        build job: 'packaging_build_rpm', propagate: true, parameters: [
                            string(name: 'branch', value: "rpm/${versions[foreman_version]['branch']}"),
                            string(name: 'project', value: 'packages/katello/katello-installer'),
                            booleanParam(name: 'gitrelease', value: false),
                            booleanParam(name: 'scratch', value: false),
                            string(name: 'releaser', value: 'koji-katello-jenkins'),
                            string(name: 'nightly_jenkins_job', value: env.getProperty('JOB_NAME')),
                            string(name: 'nightly_jenkins_job_id', value: env.getProperty('BUILD_ID'))
                        ]
                    }
                }
                stage('build-rubygem-katello-rpm') {
                    steps {
                        build job: 'packaging_build_rpm', propagate: true, parameters: [
                            string(name: 'branch', value: "rpm/${versions[foreman_version]['branch']}"),
                            string(name: 'project', value: 'packages/katello/rubygem-katello'),
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
    }
    post {
        always {
            deleteDir()
            cleanupRVM('', ruby)
        }
    }
}
