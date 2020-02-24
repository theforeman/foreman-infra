def commit_hash = ''
def source_project_name = "${project_name}-${git_ref}-source-release"

pipeline {
    agent { label 'rpmbuild' }

    options {
        timestamps()
        timeout(time: 3, unit: 'HOURS')
        ansiColor('xterm')
    }

    stages {
        stage('Build Package') {
            parallel {
                stage('Build RPM') {
                    when {
                        expression { build_rpm }
                    }
                    stages {
                        stage('Copy Source') {
                            steps {
                                script {
                                    artifact_path = "${pwd()}/artifacts"
                                    copyArtifacts(projectName: source_project_name, target: artifact_path)
                                    commit_hash = readFile("${artifact_path}/commit")
                                }
                            }
                        }
                        stage('Setup Environment') {
                            steps {
                                dir('foreman-packaging') {
                                    git(url: 'https://github.com/theforeman/foreman-packaging.git', branch: 'rpm/develop', poll: false)
                                }
                                setup_obal()
                            }
                        }
                        stage('Release') {
                            steps {
                                dir('foreman-packaging') {
                                    obal(
                                        action: 'nightly',
                                        packages: obal_package_name,
                                        extraVars: [
                                            'releasers': releasers,
                                            'nightly_sourcefiles': artifact_path,
                                            'nightly_githash': commit_hash
                                        ]
                                    )
                                }
                            }
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
            deleteDir()
        }
    }
}
