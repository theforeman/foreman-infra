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
                git url: git_url, branch: git_ref
                script {
                    archive_git_hash()
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
                    git url: git_url, branch: git_ref
                }
                script {
                    generate_sourcefiles(project_name: project_name, source_type: source_type)
                }
            }
        }
        stage('Build Packages') {
            steps {
                build(
                    job: "${project_name}-${git_ref}-package-release",
                    propagate: false,
                    wait: false
                )
            }
        }
    }
    post {
        failure {
            notifyDiscourse(env, "${project_name} source release pipeline failed:", currentBuild.description)
        }
        always {
            deleteDir()
        }
    }
}
