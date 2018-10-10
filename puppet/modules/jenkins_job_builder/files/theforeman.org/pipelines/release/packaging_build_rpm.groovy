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
                git(url: 'https://github.com/theforeman/foreman-packaging/', branch: env.branch)
                setup_obal()
            }
        }

        stage("Build RPM") {
            steps {
                script {
                    sh("mkdir -p ${env.WORKSPACE}/rel-eng/build")

                    def build_package_tito_releaser_args = "-o ${env.WORKSPACE}/rel-eng/build/"

                    if (env.tag) {
                        build_package_tito_releaser_args += " --tag=${env.tag}"
                    }
                    if (env.nightly_jenkins_job) {
                        build_package_tito_releaser_args += " --arg jenkins_job=${env.nightly_jenkins_job}"
                    }
                    if (env.nightly_jenkins_job_id) {
                        build_package_tito_releaser_args += " --arg jenkins_job_id=${env.nightly_jenkins_job_id}"
                    }

                    obal(
                        action: 'release',
                        extraVars: [
                            'build_package_tito_releaser_args': [build_package_tito_releaser_args],
                            'releaser': env.releaser
                        ],
                        packages: env.project.tokenize('/').last()
                    )
                }
            }
        }
    }
}
