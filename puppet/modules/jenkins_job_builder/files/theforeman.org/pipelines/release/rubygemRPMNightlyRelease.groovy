/*
 * this pipeline assumes you've set a handful of groovy variables
 *
 * owner_repo
 * branch
 * gemspec
 * package_name
 */

def obalExtraVars = [
    'build_package_tito_releaser_args': [
        "--arg jenkins_job=${env.JOB_NAME}",
        "--arg jenkins_job_id=${env.BUILD_ID}"
    ],
    'releasers': [
        'koji-katello-jenkins'
    ]
]

def ruby_version = '2.5'

pipeline {
    agent { label 'rpmbuild' }

    options {
        timestamps()
        timeout(time: 2, unit: 'HOURS')
        ansiColor('xterm')
    }

    stages {
        stage ("Build Gem") {
            steps {
                dir('gem-build') {
                    git(url: "https://github.com/${owner_repo}", branch: branch)
                    withRVM(["gem build ${gemspec}"], ruby_version)
                    archiveArtifacts(artifacts: '*.gem')
                }
            }
        }
        stage('Setup Build Environment') {
            steps {
                dir('foreman-packaging') {
                    git(url: 'https://github.com/theforeman/foreman-packaging', branch: 'rpm/develop', poll: false)
                }
                setup_obal()
            }
        }
        stage('Build RPM') {
            steps {
                dir('foreman-packaging') {
                    obal(action: "nightly", extraVars: obalExtraVars, packages: package_name)
                }
            }
        }
    }

    post {
        always {
            echo "Cleaning up workspace"
            cleanupRVM(ruby_version)
            deleteDir()
        }
    }
}
