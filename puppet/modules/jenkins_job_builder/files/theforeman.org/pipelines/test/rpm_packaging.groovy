def packages_to_build
def packages = [:]

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
                setup_obal()

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

        stage('Lint Spec') {
            when {
                expression { packages_to_build }
            }
            steps {

                script {
                    for(int i = 0; i < packages_to_build.size(); i++) {
                        def index = i
                        packages[packages_to_build[index]] = {
                            obal(action: "lint", packages: packages_to_build[index])
                        }
                    }

                    parallel packages
                }
            }
        }

        stage('Scratch Build Packages') {
            when {
                expression { packages_to_build }
            }
            steps {

                obal(action: "scratch", extraVars: ['build_package_download_logs': 'True', 'build_package_download_rpms': 'True'], packages: packages_to_build)

            }
        }

        stage('Repoclosure') {
            when {
                expression { packages_to_build }
            }
            steps {

                obal(action: "repoclosure", packages: packages_to_build)

            }
        }
    }

    post {
        always {
            status_koji_links("${currentBuild.getCurrentResult()}", ghprbGhRepository.split('/')[1])
        }
    }
}
