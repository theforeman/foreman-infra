def commit_hash = ''
def sourcefile = ''

pipeline {
    agent { label 'rpmbuild' }

    options {
        timestamps()
        timeout(time: 2, unit: 'HOURS')
        ansiColor('xterm')
    }

    environment {
        ruby_version = "2.4"
    }

    stages {
        stage('Setup Environment') {
            steps {
                dir('foreman-installer') {
                    git(url: 'https://github.com/theforeman/foreman-installer.git', branch: 'develop')
                    script { commit_hash = sh(script: "git rev-parse HEAD | tee commit", returnStdout: true).trim() }
                    archiveArtifacts(artifacts: 'commit')
                }
                dir('foreman-packaging') { git(url: 'https://github.com/theforeman/foreman-packaging.git', branch: 'rpm/develop') }
                setup_obal()
                configureRVM(env.ruby_version)
            }
        }
        stage('Build and Archive Source') {
            steps {
                dir('foreman-installer') {
                    withRVM(["bundle install --jobs 5 --retry 5"], env.ruby_version)
                    withRVM(["bundle exec rake pkg:generate_source"], env.ruby_version)
                    archiveArtifacts(artifacts: 'pkg/*')
                    dir('pkg') {
                        script { sourcefile = sh(script: "ls", returnStdout: true).trim() } // i could probably do this with a better built-in
                    }
                }
            }
        }
        stage('Build Package') {
            parallel {
                stage('Build RPM') {
                    steps {
                        dir('foreman-packaging') {
                            obal(
                                action: 'nightly',
                                packages: 'foreman-installer',
                                extraVars: [
                                    'build_package_scratch': true,
                                    'releasers': [ 'koji-foreman' ], // TODO: remove releasers once foreman-installer is set to `{}` in foreman-packaging
                                    'nightly_sourcefiles': [ "${env.WORKSPACE}/foreman-installer/pkg/${sourcefile}" ],
                                    'nightly_githash': commit_hash
                                ]
                            )
                        }
                    }
                }
                stage('Build DEB') {
                    steps {
                        build(
                            job: 'release_nightly_build_deb',
                            propogate: true,
                            parameters: [
                               string(name: 'project', value: 'foreman-installer'),
                               string(name: 'jenkins_job', value: env.JOB_NAME),
                               string(name: 'jenkins_job_id', value: env.BUILD_ID)
                            ]
                        )
                    }
                }
            }
        }
    }

    post {
        always {
            echo "Cleaning up workspace"
            cleanupRVM(env.ruby_version)
            deleteDir()
        }
    }
}
