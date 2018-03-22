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
                    changed_packages = sh(returnStdout: true, script: "git diff origin/master --name-only -- 'packages/*.spec' | cut -d'/' -f2 |sort -u").trim()
                    packages_to_build = changed_packages.split().join(' ')
                    update_build_description_from_packages(packages_to_build)
                }

            }
        }
        stage('Scratch Build Packages') {
            when {
                expression { packages_to_build != '' }
            }
            steps {

                obal(
                    action: 'scratch',
                    packages: packages_to_build
                )

            }
        }
        stage('Check Repoclosure') {
            when {
                expression { packages_to_build != '' }
            }
            steps {

                obal(
                    action: 'repoclosure',
                    packages: 'all',
                    extraVars: readYaml(file: '.tmp/copr_repo')
                )

            }
        }
    }
}

def update_build_description_from_packages(packages_to_build) {
    build_description = "${packages_to_build}"
    currentBuild.description = build_description
}
