def commit_hash = ''
def sourcefile = ''

pipeline {
    agent { label 'rpmbuild' }

    options {
        timestamps()
        timeout(time: 3, unit: 'HOURS')
        ansiColor('xterm')
    }

    environment {
        ruby_version = "2.4"
    }

    stages {
        stage('Setup Environment') {
            steps {
                script {
                    if (!env.git_ref) {
                        error("git_ref parameter is blank")
                    }
                }
                setup_nightly_build_environment(
                    git_url: git_url,
                    git_ref: env.git_ref ?: git_ref,
                    project_name: project_name
                )
            }
        }
        stage('Archive Git Commit') {
            steps {
                script {
                    dir(project_name) {
                        commit_hash = archive_git_hash()
                    }
                }
            }
        }
        stage('Build and Archive Source') {
            steps {
                script {
                    sourcefile_paths = generate_sourcefiles(project_name: project_name, source_type: source_type)
                }
            }
        }
        stage('Build Package') {
            parallel {
                stage('Build RPM') {
                    when {
                        expression { build_rpm }
                    }
                    steps {
                        dir('foreman-packaging') {
                            obal(
                                action: 'nightly',
                                packages: obal_package_name,
                                extraVars: [
                                    'releasers': releasers,
                                    'nightly_sourcefiles': sourcefile_paths,
                                    'nightly_githash': commit_hash
                                ]
                            )
                        }
                    }
                }
                stage('Build DEB') {
                    when {
                        expression { build_deb }
                    }
                    steps {
                        build(
                            job: 'release_nightly_build_deb',
                            propagate: true,
                            parameters: [
                               string(name: 'project', value: project_name),
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
