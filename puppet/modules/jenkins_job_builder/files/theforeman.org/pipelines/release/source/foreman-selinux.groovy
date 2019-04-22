def commit_hash = ''
source_type = 'rake'
foreman_branch = 'develop'
project_name = 'foreman-selinux'

pipeline {
    agent { label 'el' }

    options {
        timestamps()
        timeout(time: 2, unit: 'HOURS')
        ansiColor('xterm')
    }

    stages {
        stage("Collect Git Hash") {
            steps {
                git(url: 'https://github.com/theforeman/foreman-selinux', branch: 'develop')
                script {
                    commit_hash = archive_git_hash()
                }
            }
        }
        stage("Build for rhel7") {
            steps {
                script {
                    distro = 'rhel7'
                    instprefix = pwd(tmp: true)
                }
                sh "make INSTPREFIX=${instprefix}/${distro} DISTRO=${distro}"
            }
        }
        stage('Build and Archive Source') {
            steps {
                dir(project_name) {
                    git url: "https://github.com/theforeman/${project_name}", branch: foreman_branch
                }
                script {
                    sourcefile_paths = generate_sourcefiles(project_name: project_name, source_type: source_type)
                }
            }
        }
        stage('Build Packages') {
            steps {
                build(
                    job: "${project_name}-${foreman_branch}-package-release",
                    propagate: false,
                    wait: false,
                    parameters: [
                        string(name: 'git_ref', value: commit_hash)
                    ]
                )
            }
        }
    }
    post {
        always {
            deleteDir()
        }
    }
}
