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

                setup_obal()
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
                expression { packages_to_build != [] }
            }
            steps {

                obal(
                    action: 'release',
                    packages: packages_to_build
                )

            }
        }
        stage('Mash Koji Repositories') {
            agent { label 'sshkey' }

            steps {

                sh "koji regen-repo tfm-ror52-rhel7-build"
                sh "ssh -o 'BatchMode yes' root@koji.katello.org tfm-ror52-mash-split.py"

            }
        }
        stage('Push RPMs') {
            agent { label 'admin && sshkey' }

            steps {
                git url: 'https://github.com/theforeman/foreman-infra'

                dir('deploy') {
                    withRVM(["bundle install --jobs=5 --retry=5"])
                    push_rpms('rails', 'foreman-nightly', 'el7')
                }
            }
            post {
                always {
                    deleteDir()
                }
            }
        }
    }

    post {
        success {
            archive_git_hash()
        }
    }
}
