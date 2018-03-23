def packages_to_build

pipeline {
    agent { label 'rpmbuild' }

    options {
        timestamps()
        timeout(time: 2, unit: 'HOURS')
        ansiColor('xterm')
        buildDiscarder(logRotator(numToKeepStr: '15'))
    }

    stages {
        stage('Clone Packaging') {
            steps {

                deleteDir()
                ghprb_git_checkout()

            }
        }

        stage('Find Packages to Build') {
            steps {

                script {
                    packages_to_build = find_changed_packages("origin/${ghprbTargetBranch}")

                    update_build_description_from_packages(packages_to_build)
                }

            }
        }

        stage('Scratch Build Packages') {
            when {
                expression { packages_to_build }
            }
            steps {

                obal(action: "scratch", extraVars: ['build_package_download_logs': 'True'], packages: packages_to_build)

            }
        }
    }

    post {
        always {
            status_koji_links("${currentBuild.getCurrentResult()}")
        }
    }
}
