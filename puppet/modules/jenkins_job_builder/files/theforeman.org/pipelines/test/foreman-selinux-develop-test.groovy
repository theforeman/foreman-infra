def commit_hash = ''

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
        stage("Release Nightly Package") {
            steps {
                build(
                    job: 'foreman-selinux-develop-release',
                    propagate: false,
                    wait: false
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
