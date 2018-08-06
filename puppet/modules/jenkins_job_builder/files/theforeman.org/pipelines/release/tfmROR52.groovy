def packages_to_build

pipeline {
    agent { label 'rpmbuild' }

    options {
        timestamps()
        timeout(time: 2, unit: 'HOURS')
        ansiColor('xterm')
    }

    stages {
        stage('Clone Packaging') {
            steps {

                checkout([
                    $class : 'GitSCM',
                    branches : [[name: '*/tfm-ror52']],
                    extensions: [[$class: 'CleanCheckout']],
                    userRemoteConfigs: [
                        [url: 'https://github.com/theforeman/rails-packaging']
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

                        packages_to_build = 'all'

                    }
                }
            }
        }
        stage('Release Build Packages') {
            when {
                expression { packages_to_build != '' }
            }
            steps {

                obal(
                    action: 'release',
                    packages: packages_to_build
                )

            }
        }
    }

    post {
        success {
            // Save current commit hash for use by the next release run
            sh "git rev-parse HEAD > commit"
            archiveArtifacts artifacts: 'commit'
        }
    }
}
