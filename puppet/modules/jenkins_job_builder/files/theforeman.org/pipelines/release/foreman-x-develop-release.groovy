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
        ruby_version = "2.5"
    }

    stages {
        stage('Copy Source') {
            steps {
                script {
                    sourcefile_paths = pwd(tmp: true)
                    source_project_name = "${project_name}-${git_ref}-source-release"
                    copyArtifacts(projectName: source_project_name, target: sourcefile_paths, selector: {lastSuccessful: true})
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
                               string(name: 'jenkins_job', value: source_project_name),
                            ]
                        )
                    }
                }
            }
        }
    }

    post {
        failure {
            notifyDiscourse(env, "${project_name} package release pipeline failed:", currentBuild.description)
        }
        always {
            echo "Cleaning up workspace"
            cleanupRVM(env.ruby_version)
            deleteDir()
        }
    }
}
