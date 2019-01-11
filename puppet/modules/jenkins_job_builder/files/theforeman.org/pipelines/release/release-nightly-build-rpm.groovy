def releaserArgs = []

pipeline {
    agent { label 'rpmbuild' }

    options {
        timestamps()
        timeout(time: 2, unit: 'HOURS')
        ansiColor('xterm')
    }

    stages {
        stage("Setup Environment") {
            steps {
                git(url: 'https://github.com/theforeman/foreman-packaging/', branch: 'rpm/develop', poll: false)
                setup_obal()
            }
        }

        stage("Obal Nightly Build RPM") {
            steps {
                script {
                    if (env.jenkins_job) {
                        releaserArgs << "--arg jenkins_job=${env.jenkins_job}"
                    }
                    if (env.jenkins_job_id) {
                        releaserArgs << "--arg jenkins_job_id=${env.jenkins_job_id}"
                    }
                }
                obal(
                    action: 'nightly',
                    packages: env.project.tokenize('/').last(),
                    extraVars: ['build_package_tito_releaser_args': releaserArgs] // since the jenkins_job_id defaults to 'lastSuccessfulBuild' we'll always have something here
                )
            }
        }
    }
}
