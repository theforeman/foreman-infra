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
                script {
                    commit_hash = setup_nightly_build_environment(
                        github_repo: 'theforeman/smart-proxy',
                        package_name: 'foreman-proxy',
                    )
                }
            }
        }
        stage('Build and Archive Source') {
            steps {
                script {
                    sourcefile_paths = generate_nightly_sourcefiles(
                        package_name: 'foreman-proxy'
                    )
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
                                packages: 'foreman-proxy',
                                extraVars: [
                                    'releasers': [ 'koji-foreman' ],
                                    'nightly_sourcefiles': sourcefile_paths,
                                    'nightly_githash': commit_hash,
                                    'build_package_scratch': true
                                ]
                            )
                        }
                    }
                }
                stage('Build DEB') {
                    steps {
                        echo "TODO"
                        // build(
                        //     job: 'release_nightly_build_deb',
                        //     propagate: true,
                        //     parameters: [
                        //         string(name: 'project', value: 'foreman-proxy'),
                        //         string(name: 'jenkins_job', value: env.JOB_NAME),
                        //         string(name: 'jenkins_job_id', value: env.BUILD_ID)
                        //     ]
                        // )
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
