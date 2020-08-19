def packages_to_build

pipeline {
    agent { label 'rpmbuild' }

    options {
        timestamps()
        timeout(time: 4, unit: 'HOURS')
        disableConcurrentBuilds()
        ansiColor('xterm')
    }

    stages {
        stage('Clone Packaging') {
            steps {
                checkout([
                    $class : 'GitSCM',
                    branches : [[name: "*/${packaging_branch}"]],
                    extensions: [[$class: 'CleanCheckout']],
                    userRemoteConfigs: [
                        [url: 'https://github.com/theforeman/pulpcore-packaging']
                    ]
                ])

            }
        }
        stage('Find packages') {
            steps {
                copyArtifacts(projectName: env.JOB_NAME, optional: true)

                script {

                    if (fileExists('commit')) {

                        commit = readFile(file: 'commit').trim()
                        packages_to_build = find_changed_packages("${commit}..HEAD")

                    } else {

                        packages_to_build = []

                    }
                }
            }
        }
        stage('Release Build Packages') {
            when {
                expression { packages_to_build != [] }
            }
            steps {

                setup_obal()
                obal(
                    action: 'release',
                    packages: packages_to_build
                )

            }
        }
    }

    post {
        success {
            archive_git_hash()
        }
        failure {
            notifyDiscourse(
              env,
              "${env.JOB_NAME} failed for ${packages_to_build.join(',')}",
              "pulpcore packaging release job failed: ${env.BUILD_URL}"
            )
        }
    }
}
