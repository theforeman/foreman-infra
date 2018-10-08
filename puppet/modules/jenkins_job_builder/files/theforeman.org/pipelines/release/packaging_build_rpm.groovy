pipeline {
    agent { label 'rpmbuild' }

    options {
        timestamps()
        timeout(time: 2, unit: 'HOURS')
        disableConcurrentBuilds()
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
            when {
                anyOf {
                    expression { env.pr_git_url != null && env.scratch == 'true' }
                    expression { env.pr_git_url == null }
                }
            }
            steps {
                script {
                    sh("mkdir -p ${env.WORKSPACE}/rel-eng/build")

                    def build_package_tito_releaser_args = "-o ${env.WORKSPACE}/rel-eng/build/"
                    def build_package_scratch = false
                    def build_package_test = false

                    if (env.tag) {
                        build_package_tito_releaser_args += " --tag=${env.tag}"
                    }
                    if (env.scratch) {
                        build_package_scratch = true
                    }
                    if (env.gitrelease && env.releaser != 'koji-foreman-nightly' && env.releaser != 'koji-foreman-jenkins') {
                        build_package_test = true
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
                            'build_package_scratch': build_package_scratch,
                            'build_package_test': build_package_test,
                            'releaser': env.releaser
                        ],
                        packages: env.project.tokenize('/').last()
                    )
                }
            }
        }
    }
}
