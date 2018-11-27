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
                        git_url: git_url,
                        package_name: package_name,
                        branch: branch
                    )
                }
            }
        }
        stage('Build and Archive Source') {
            steps {
                script {
                    sourcefile_paths = generate_nightly_sourcefiles(
                        package_name: package_name
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
                                packages: package_name,
                                extraVars: [
                                    'releasers': [ 'koji-foreman' ],
                                    'nightly_sourcefiles': sourcefile_paths,
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
                            propagate: true,
                            parameters: [
                               string(name: 'project', value: package_name),
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
