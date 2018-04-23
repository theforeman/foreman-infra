pipeline {
    agent { label 'admin' }

    option {
        timestamps()
        timeout(time: 2, unit: 'HOURS')
        disableConcurrentBuilds()
        ansiColor('xterm')
    }

    stages {
        stage ("Build Gem") {
            steps {
                dir('hammer_cli_katello') {
                    git url: "https://github.com/Katello/hammer-cli-katello", branch: 'master'
                    sh "gem build hammer_cli_katello.gemspec"
                    archiveArtifacts artifacts '*.gem'
                }
            }
        }

        stage('Trigger RPM Build') {
            steps {
                build job: 'packaging_build_rpm', propagate: true, parameters: [
                    string(name: 'project', value: 'packages/katello/hammer_cli_katello')
                    booleanParam(name: 'gitrelease', value: false),
                    booleanParam(name: 'scratch', value: false),
                    string(name: 'nightly_jenkins_job', value: env.getProperty('JOB_NAME')),
                    string(name: 'nightly_jenkins_job_id', value: env.getProperty('BUILD_ID'))
                ]
            }
        }
    }
}
