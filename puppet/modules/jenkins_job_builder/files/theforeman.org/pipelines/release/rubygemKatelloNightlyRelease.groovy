pipeline {
    agent { label 'admin' }

    environment {
        RUBY = '2.2'
    }

    options {
        timestamps()
        timeout(time: 60, unit: 'MINUTES')
        disableConcurrentBuilds()
        ansiColor('xterm')
    }

    stages {
        stage ("Build Gem") {
            steps {
                dir('katello') {
                    configureRVM(env.RUBY)
                    git url: "https://github.com/Katello/katello", branch: 'master'
                    withRVM(["gem build katello.gemspec"], env.RUBY)
                    archiveArtifacts artifacts: '*.gem'
                }
            }
        }

        stage('Trigger RPM Build') {
            steps {
                build job: 'packaging_build_rpm', propagate: true, parameters: [
                    string(name: 'project', value: 'packages/katello/rubygem-katello'),
                    booleanParam(name: 'gitrelease', value: false),
                    booleanParam(name: 'scratch', value: false),
                    string(name: 'releaser', value: 'koji-katello-jenkins'),
                    string(name: 'nightly_jenkins_job', value: env.getProperty('JOB_NAME')),
                    string(name: 'nightly_jenkins_job_id', value: env.getProperty('BUILD_ID'))
                ]
            }
        }
    }
}
